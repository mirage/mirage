(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(* TCPv4 implementation, heavily based on the lwIP-1.3.2 state machine *)

open Lwt
open Mlnet_types
open Printf

module type UP = sig
  type t
  val input: t -> Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t
  val output: t -> dest_ip:ipv4_addr -> (Mpl.Mpl_stdlib.env -> Mpl.Tcp.o) -> unit Lwt.t
  val listen: t -> int -> (Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t) -> unit
end

module TCP(IP:Ipv4.UP) = struct

  type state =
  |Closed
  |Listen
  |Syn_sent
  |Syn_received
  |Established
  |Fin_wait_1
  |Fin_wait_2
  |Close_wait
  |Closing
  |Last_ack
  |Time_wait

  and flags = {
    ack_delay: bool;     (* Delayed ACK *)
    ack_now: bool;       (* Immediate ACK *)
    fast_recovery: bool; (* Fast recovery mode *)
    timestamp: bool;     (* Timestamp option enabled *)
    fin: bool;           (* Local connection closed *)
    no_delay: bool;      (* Disable nagle *)
  }

  and wnd = {
    mutable rcv_nxt: int32;     (* Next expected sequence no *)
    mutable rcv_wnd: int;        (* Receiver window available *)
    mutable rcv_ann_wnd: int;    (* Receiver window to announce *)
    mutable rcv_ann_edge: int; (* Announced right edge of window *)
    mss: int;                    (* Maximum segment size *)
    mutable snd_nxt: int32;      (* Next new seqno to be sent *)
    mutable snd_wnd: int;        (* Sender window *)
    mutable snd_wl1: int32;
    mutable snd_wl2: int32;      (* Seq and ack num of last wnd update *) 
    mutable snd_lbb: int32;      (* Seq of next byte to be buffered *)
  }

  and pcb = {
    mutable state: state;  (* Connection state *)
    flags: flags;          (* Connection flags *)
    remote_port: int;      (* Remote TCP port *)
    remote_ip: ipv4_addr;  (* Remote IP address *)
    local_port: int;       (* Local TCP port *)
    local_ip: ipv4_addr;   (* Local IP address *)
    wnd: wnd;              (* Window information *)
  } 
 
  type todo = {   
    (* RTT estimation variables *)
    rttest: int32;       (* RTT estimate in 500ms ticks *)
    rtseq: int32;        (* Sequence number being timed *)
    rto: int;            (* Retransmission timeout *)
    rtx: int;            (* Number of retransmissions *)
    
    (* Fast transmit/recovery *)
    lastack: int32;      (* Last acknowleged seqno *)
    dupacks: int;
 
    (* Congestion avoidance variables *)
    cwnd: int;
    ssthresh: int;
  }

  type conn_id = {
    c_remote_port: int;
    c_remote_ip: ipv4_addr;
    c_local_port: int;
    c_local_ip: ipv4_addr
  }

  type t = {
    ip : IP.t;
    pcbs: (conn_id, pcb) Hashtbl.t ;
    listeners: (int, (Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t)) Hashtbl.t ;
  }

  (* Global values for TCP parameters *)
  let tcp_mss = 566
  let tcp_wnd = tcp_mss * 4

  let string_of_state = function
  |Closed -> "closed"
  |Listen -> "listen"
  |Syn_sent -> "syn_sent"
  |Syn_received -> "syn_recv"
  |Established -> "established"
  |Fin_wait_1 -> "fin_wait_1"
  |Fin_wait_2 -> "fin_wait_2"
  |Close_wait -> "close_wait"
  |Closing -> "closing"
  |Last_ack -> "last_ack"
  |Time_wait -> "time_wait"

  (* Output a general TCP packet and checksum it *)
  let output_tcp_low t ~dest_ip fn =
    let tcpfn env = 
      let p = fn env in
      let csum = Checksum.tcp (IP.get_ip t.ip) dest_ip p in
      p#set_checksum csum;
      Mpl.Tcp.prettyprint p;
    in
    let src_ip = ipv4_addr_to_uint32 (IP.get_ip t.ip) in
    let id = 30 in (* XXX random *)
    let ipfn env = Mpl.Ipv4.t ~src:src_ip ~protocol:`TCP ~id ~data:(`Sub tcpfn) env in
    IP.output ~dest_ip t.ip ipfn

  (* Output a RST control packet to reset a connection *) 
  let output_tcp_rst t ~dest_ip ~source_port ~dest_port ~sequence ~ack_number =
    printf "TCP: xmit RST -> %s:%d\n%!" (ipv4_addr_to_string dest_ip) dest_port;
    output_tcp_low t ~dest_ip (
      Mpl.Tcp.t ~rst:1 ~ack:1
        ~source_port ~dest_port ~sequence ~ack_number 
        ~window:tcp_wnd ~checksum:0 ~data:`None ~options:`None)

  (* Output a SYN ACK control packet to open a connection *)
  let output_syn_ack t ~dest_ip pcb =
    printf "TCP: xmit SYN/ACK -> %s:%d\n%!" (ipv4_addr_to_string pcb.remote_ip) pcb.remote_port;
    let sequence = 0xdeadbeefl in (* XXX obviously *)
    let ack_number = pcb.wnd.rcv_nxt in
    output_tcp_low t ~dest_ip (
      Mpl.Tcp.t ~syn:1 ~ack:1
        ~source_port:pcb.local_port ~dest_port:pcb.remote_port ~sequence ~ack_number
        ~window:tcp_wnd ~checksum:0 ~data:`None ~options:`None)

  (* Process an incoming TCP packet that has an active PCB *)
  let tcp_process_input ip tcp pcb =
    match pcb.state with
    | Syn_received -> begin
        printf "TCP: syn_sent, hoping for ack\n%!";
        return ()
      end
    | _ -> return (printf "unknown pcb state: %s\n%!" (string_of_state pcb.state))

  (* Helper function to apply function with contents of hashtbl, or take default action *)
  let with_hashtbl h k fn default =
    try fn (Hashtbl.find h k) with Not_found -> default ()

  (* Main input function for TCP packets *)
  let input t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) =
    (* Construct a connection ID from the input packet to look it up in PCB list *)
    let conn_id = {
      c_remote_port = tcp#source_port;
      c_remote_ip = ipv4_addr_of_uint32 ip#src;
      c_local_ip = IP.get_ip t.ip;
      c_local_port = tcp#dest_port;
    } in
    (* Lookup connection from the active PCB hash *)
    with_hashtbl t.pcbs conn_id
      (* PCB exists, so continue the connection state machine in tcp_input *)
      (tcp_process_input ip tcp)
      (* No existing PCB, so check if it is a SYN for a listening function *)
      (fun () ->
        let syn_no_ack = (tcp#syn = 1) && (tcp#ack = 0) in
        match syn_no_ack with
        (* This is a pure SYN, no ACK packet *) 
        |true ->
          (* Try to find a listener *)
          let local_port = tcp#dest_port in
          let remote_port = tcp#source_port in
          let dest_ip = ipv4_addr_of_uint32 ip#src in
          with_hashtbl t.listeners local_port 
            (* Got a listener, construct new PCB and send ACK *)
            (fun listener ->
              (* All flags off by default. XXX handle TCP timestamp here *)
              let flags = { ack_delay=false; ack_now=false; fast_recovery=false;
                timestamp=false; fin=false; no_delay=false } in
              (* Set up the windowing variables *)
              let rcv_wnd = tcp#window in
              let seqno = tcp#sequence in
              let snd_wl1 = Int32.pred seqno in (* XXX to force an update, but what if seq=0? *)
              let wnd = { rcv_nxt=(Int32.succ seqno);
                rcv_wnd; rcv_ann_wnd=0; rcv_ann_edge=rcv_wnd; mss=tcp_mss;
                snd_wnd=rcv_wnd; snd_nxt=0l; snd_wl1; snd_wl2=0l; snd_lbb=0l } in
              (* Construct basic PCB in Syn_received state *)
              let pcb = { state=Syn_received; flags; wnd; remote_port;
                remote_ip=(ipv4_addr_of_uint32 ip#src); local_port;
                local_ip=(IP.get_ip t.ip) } in
              (* Add the PCB to our connection table *)
              Hashtbl.add t.pcbs conn_id pcb;
              (* Reply with SYN ACK *)
              output_syn_ack t ~dest_ip pcb;
            )
            (* Send a TCP RST since we dont have a listener *)
            (fun () -> output_tcp_rst t
                ~dest_ip
                ~source_port:local_port
                ~dest_port:remote_port
                ~sequence:0l
                ~ack_number:(Int32.succ tcp#sequence) (* XXX should also include tcp#data_length? *)
            )
        |false -> 
          (* Got an older SYN ACK perhaps, discard it *)
          printf "TCP: discarding unknown TCP packet\n%!";
          return ()
      )           

  (* Register a TCP listener on a port *)
  let listen t port fn =
    if Hashtbl.mem t.listeners port then
      printf "WARNING: TCP listen port %d already used\n%!" port;
    Hashtbl.replace t.listeners port fn

  (* Construct the main TCP thread *)
  let create ip =
    let thread, _ = Lwt.task () in
    let listeners = Hashtbl.create 1 in
    let pcbs = Hashtbl.create 7 in
    let t = { ip; listeners; pcbs } in
    IP.attach ip (`TCP (input t));
    Lwt.on_cancel thread (fun () ->
      printf "TCP: shutting down\n%!";
      IP.detach ip `TCP;
    );
    (t, thread)

end

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

  type flags = {
    ack_delay: bool;     (* Delayed ACK *)
    ack_now: bool;       (* Immediate ACK *)
    fast_recovery: bool; (* Fast recovery mode *)
    timestamp: bool;     (* Timestamp option enabled *)
    fin: bool;           (* Local connection closed *)
    no_delay: bool;      (* Disable nagle *)
  }

  type pcb = {
    state: state;          (* Connection state *)
    flags: flags;          (* Connection flags *)
    remote_port: int;      (* Remote TCP port *)
    remote_ip: ipv4_addr;  (* Remote IP address *)
    local_port: int;       (* Local TCP port *)
    local_ip: ipv4_addr;   (* Local IP address *)
  }

  type active = {   
    (* Receiver info *)
    rcv_nxt: int32;      (* Next expected sequence no *)
    rcv_wnd: int;        (* Receiver window available *)
    rcv_ann_wnd: int;    (* Receiver window to announce *)
    rcv_ann_edge: int32; (* Announced right edge of window *)
    mss: int;            (* Maximum segment size *)

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

    (* Sender info *)
    snd_nxt: int32;      (* Next new seqno to be sent *)
    snd_wnd: int;        (* Sender window *)
    snd_wl1: int32;
    snd_wl2: int32;      (* Seq and ack num of last wnd update *) 
    snd_lbb: int32;      (* Seq of next byte to be buffered *)
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

  let state_to_string = function
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
 
  let output_tcp_rst t ~dest_ip ~source_port ~dest_port ~sequence ~ack_number =
    printf "TCP: xmit RST -> %s:%d\n%!" (ipv4_addr_to_string dest_ip) dest_port;
    let tcpfn env =
      let p = Mpl.Tcp.t ~rst:1 ~ack:1
        ~source_port ~dest_port ~sequence ~ack_number 
        ~window:tcp_wnd ~checksum:0 ~data:`None ~options:`None env in
      let csum = Checksum.tcp (IP.get_ip t.ip) dest_ip p in
      p#set_checksum csum;
Mpl.Tcp.prettyprint p;
    in
    let src_ip = ipv4_addr_to_uint32 (IP.get_ip t.ip) in
    let ipfn env = Mpl.Ipv4.t ~src:src_ip ~protocol:`TCP ~id:30 ~data:(`Sub tcpfn) env in
    IP.output ~dest_ip t.ip ipfn

  let input t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) =
    let conn_id = {
      c_remote_port = tcp#source_port;
      c_remote_ip = ipv4_addr_of_uint32 ip#src;
      c_local_ip = IP.get_ip t.ip;
      c_local_port = tcp#dest_port;
    } in
    try begin
      let pcb = Hashtbl.find t.pcbs conn_id in
      print_endline "found pcb";
      return ()
    end with Not_found -> begin
      (* No existing PCB, so check if it's a SYN for a listener *)
      match tcp#syn, tcp#ack with 
      |1,0 -> begin (* This is a pure SYN, no ACK packet *) 
          (* Try to find a listener *)
          try
            let listener = Hashtbl.find t.listeners tcp#dest_port in
            (* Got a listener, send ACK *)
            print_endline "get a listener send ack";
            return ()
          with Not_found -> begin
            (* Send a TCP RST since we dont have a listener *)
            output_tcp_rst t
              ~dest_ip:(ipv4_addr_of_uint32 ip#src)
              ~source_port:tcp#dest_port
              ~dest_port:tcp#source_port
              ~sequence:0l
              ~ack_number:(Int32.succ tcp#sequence)
            
          end

      end
      |_ -> return () 
    end

  let listen t port fn =
    if Hashtbl.mem t.listeners port then
      printf "WARNING: UDP listen port %d already used\n%!" port;
    Hashtbl.replace t.listeners port fn

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

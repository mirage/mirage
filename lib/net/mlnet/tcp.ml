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

open Lwt
open Nettypes
open Printf

exception Not_implemented of string

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

and id = {
  dest_port: int;        (* Remote TCP port *)
  dest_ip: ipv4_addr;    (* Remote IP address *)
  local_port: int;       (* Local TCP port *)
  local_ip: ipv4_addr;   (* Local IP address *)
}
and pcb = {
  id: id;
  mutable state: state;  (* Connection state *)
  wnd: Tcp_window.t;     (* Window information *)
  mutable seg: Tcp_segment.t;    (* Segment reassembly *)
}
and channel = {
  pcb: pcb;
  th: unit Lwt.t;
  buf: OS.Istring.View.t Lwt_sequence.t;
  cond: unit Lwt_condition.t;
}

type t = {
  ip : Ipv4.t;
  channels: (id, channel) Hashtbl.t ;
  listeners: (int, (pcb -> channel)) Hashtbl.t ;
}

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

module Out = struct
  (* Output a general TCP packet and checksum it *)
  let packet t id fn =
    let src = ipv4_addr_to_uint32 (Ipv4.get_ip t.ip) in
    let tcpfn env = 
      let dest_ip = ipv4_addr_to_uint32 id.dest_ip in
      let p = fn env in
      let pseudo = Int32.(add (add src dest_ip) (of_int (6+p#sizeof))) in
      let csum = OS.Istring.View.ones_complement_checksum p#env p#sizeof pseudo in
      p#set_checksum csum;
    in
    let ip_id = 30 in (* XXX random *)
    let data = `Sub tcpfn in
    let ipfn env = Mpl.Ipv4.t ~src ~protocol:`TCP ~id:ip_id ~data env in
    Ipv4.output ~dest_ip:id.dest_ip t.ip ipfn

(*
  (* Output an ACK packet *)
  let ack t ~dest_ip ~source_port ~dest_port ~sequence ~ack_number =
    printf "TCP: xmit ACK -> %s:%d\n%!" (ipv4_addr_to_string dest_ip) dest_port;
    let window = 65535 in
    let checksum = 0 in
    packet t ~dest_ip (
      Mpl.Tcp.t ~syn:0 ~ack:1
        ~source_port ~dest_port ~sequence ~ack_number
        ~window ~checksum ~data:`None ~options:`None
    )

*)
  (* Output a RST control packet to reset a connection *) 
  let rst t pcb =
    printf "TCP: xmit RST -> %s:%d\n%!" (ipv4_addr_to_string pcb.id.dest_ip) pcb.id.dest_port;
    let window = pcb.wnd.Tcp_window.rcv_wnd in (* XXX check *)
    let sequence = pcb.wnd.Tcp_window.snd_nxt in
    let ack_number = pcb.wnd.Tcp_window.rcv_nxt in
    packet t pcb.id (fun env ->
      Mpl.Tcp.t ~rst:1 ~ack:1 ~sequence ~ack_number
        ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
        ~window ~data:`None ~options:`None env
    )

  (* Output an RST when we dont have a PCB *)
  let rst_no_pcb ~sequence ~ack_number t id = 
    printf "TCP: xmit RST no pcb -> %s:%d\n%!" (ipv4_addr_to_string id.dest_ip) id.dest_port;
    packet t id (fun env ->
      Mpl.Tcp.t ~rst:1 ~ack:1 ~sequence ~ack_number
        ~source_port:id.local_port ~dest_port:id.dest_port
        ~window:0 ~data:`None ~options:`None env
    )

  (* Output a SYN ACK packet *)
  let syn_ack t pcb =
    printf "TCP: xmit SYN_ACK -> %s:%d\n%!" (ipv4_addr_to_string pcb.id.dest_ip) pcb.id.dest_port;
    let window = pcb.wnd.Tcp_window.rcv_wnd in
    let sequence = pcb.wnd.Tcp_window.snd_nxt in
    let ack_number = pcb.wnd.Tcp_window.rcv_nxt in
    packet t pcb.id (fun env ->
      Mpl.Tcp.t ~syn:1 ~ack:1 ~sequence ~ack_number
        ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
        ~window ~data:`None ~options:`None env
    )

end

(* Process an incoming TCP packet that has an active PCB *)
let tcp_process_input t ip tcp ch =
  let pcb = ch.pcb in
  match pcb.state with
  | Syn_received -> begin
      (* if it's an ACK then establish the connection *)
      match tcp#ack = 1 with
      | true -> begin
          (* check the ack number is what we're expecting *)
          match Tcp_window.valid pcb.wnd tcp#sequence with
          | true ->
              (* valid sequence, we can establish connection *)
              printf "TCP: connection established\n%!";
              pcb.state <- Established;
              ignore(Lwt_sequence.add_r tcp#data_sub_view ch.buf);
              Lwt_condition.signal ch.cond ();
              return ()
          | false ->
              (* invalid sequence number, send back an RST *)
              printf "TCP: invalid seq, sending RST\n";
              pcb.wnd.Tcp_window.snd_nxt <- tcp#ack_number;
              pcb.wnd.Tcp_window.rcv_nxt <- Int32.(add tcp#sequence (of_int tcp#data_length));
              Out.rst t pcb
        end   
      | false ->
         return ()
    end
  | Established -> begin
      match Tcp_window.valid pcb.wnd tcp#sequence with
      | true -> begin
          let ready,segs = Tcp_segment.coalesce tcp pcb.seg in
          pcb.seg <- segs;
          Lwt_condition.signal ch.cond ();
          return ()
      end
      | false ->
          printf "TCP: bad sequence number, ignoring: %lu\n%!" tcp#sequence;
          return ()
  end
  | _ -> return (printf "unknown pcb state: %s\n%!" (string_of_state pcb.state))

(* Helper function to apply function with contents of hashtbl, or take default action *)
let with_hashtbl h k fn default =
  try fn (Hashtbl.find h k) with Not_found -> default k

let tcp_new_connection t ip tcp id =
  match (tcp#syn = 1) && (tcp#ack = 0) with
  |true -> (* This is a pure SYN, no ACK packet *)
    (* Try to find a listener *)
    with_hashtbl t.listeners id.local_port
    (* Got a listener, construct new PCB and send ACK *)
      (fun listener ->
        (* Set up the windowing variables *)
        let rcv_wnd = tcp#window in
        let snd_isn = tcp#sequence in
        let wnd = Tcp_window.t ~snd_isn ~rcv_wnd in
        let seg = Tcp_segment.t snd_isn in
        (* Construct basic PCB in Syn_received state *)
        let state = Syn_received in
        let pcb = { state; seg; wnd; id } in
        let ch = listener pcb in
        (* Add the PCB to our connection table *)
        Hashtbl.add t.channels id ch;
        (* Reply with SYN ACK *)
        Out.syn_ack t pcb;
      )
      (* Send a TCP RST since we dont have a listener *)
      (fun source_port ->
         let sequence = 0l in
         let ack_number = Int32.succ tcp#sequence in
         Out.rst_no_pcb ~sequence ~ack_number t id
      )
  |false -> (* Got an older SYN ACK perhaps, discard it *)
    printf "TCP: discarding unknown TCP packet\n%!";
    return ()

(* Main input function for TCP packets *)
let input t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) =

  (* Construct a connection ID from the input packet to look it up in PCB list *)
  let dest_ip = ipv4_addr_of_uint32 ip#src in
  let dest_port = tcp#source_port in
  let local_ip = Ipv4.get_ip t.ip in
  let local_port = tcp#dest_port in
  let id = { dest_port; dest_ip; local_ip; local_port } in

  (* Lookup connection from the active PCB hash *)
  with_hashtbl t.channels id
    (* PCB exists, so continue the connection state machine in tcp_input *)
    (tcp_process_input t ip tcp)
    (* No existing PCB, so check if it is a SYN for a listening function *)
    (tcp_new_connection t ip tcp)

let output t ~dest_ip tcpfn =
  raise_lwt (Not_implemented "output")

(* Register a TCP listener on a port *)
let listen t port fn =
  if Hashtbl.mem t.listeners port then
    printf "WARNING: TCP listen port %d already used\n%!" port;
  Hashtbl.replace t.listeners port fn

(* Construct the main TCP thread *)
let create ip =
  let thread, _ = Lwt.task () in
  let listeners = Hashtbl.create 1 in
  let channels = Hashtbl.create 7 in
  let t = { ip; listeners; channels } in
  Ipv4.attach ip (`TCP (input t));
  Lwt.on_cancel thread (fun () ->
    printf "TCP: shutting down\n%!";
    Ipv4.detach ip `TCP;
  );
  (t, thread)


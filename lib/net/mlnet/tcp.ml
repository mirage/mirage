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
  |Closed |Listen |Syn_sent |Syn_received
  |Established |Fin_wait_1 |Fin_wait_2
  |Close_wait |Closing |Last_ack |Time_wait

type id = {
  dest_port: int;        (* Remote TCP port *)
  dest_ip: ipv4_addr;    (* Remote IP address *)
  local_port: int;       (* Local TCP port *)
  local_ip: ipv4_addr;   (* Local IP address *)
}

type pcb = {
  id: id;
  wnd: Tcp_window.t;                 (* Window information *)
  mutable state: state;              (* Connection state *)
  mutable rxsegs: Tcp_segment.Rx.t;  (* Received segments queue *)
  mutable txsegs: Tcp_segment.Tx.t;  (* Transmit segments queue *)
}

type view = OS.Istring.View.t
type data = Mpl.Tcp.o OS.Istring.View.data

type channel = {
  pcb: pcb;
  rxq: view Lwt_sequence.t;   (* RX segment queue *)
  rxc: unit Lwt_condition.t;  (* Receive condition mutex *)
  txq: data Lwt_sequence.t;   (* TX segment queue *)
  txc: unit Lwt_condition.t;  (* Transmit condition mutex *)
  mutable tx_closed: bool;    (* If our transmit side is closed *)
}

type t = {
  ip : Ipv4.t;
  channels: (id, (channel * unit Lwt.t)) Hashtbl.t ;
  listeners: (int, (pcb -> (channel * unit Lwt.t))) Hashtbl.t ;
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

module Tx = struct

  (* Output a general TCP packet and checksum it *)
  let packet t id (fn: view->Mpl.Tcp.o) =
    let src = ipv4_addr_to_uint32 (Ipv4.get_ip t.ip) in
    let tcpfn env = 
      let tcp = fn env in
      let dest_ip = ipv4_addr_to_uint32 id.dest_ip in
      let pseudo_header = Int32.(add (add src dest_ip) (of_int (6+tcp#sizeof))) in
      let checksum = OS.Istring.View.ones_complement_checksum tcp#env tcp#sizeof pseudo_header in
      tcp#set_checksum checksum;
  in
  let ip_id = 30 in (* XXX TODO random *)
  let data = `Sub tcpfn in
  let ipfn env = Mpl.Ipv4.t ~src ~protocol:`TCP ~id:ip_id ~data env in
  Ipv4.output ~dest_ip:id.dest_ip t.ip ipfn

  (* Output a RST control packet to reset a connection *) 
  let rst t pcb =
    printf "TCP: xmit RST -> %s:%d\n%!" (ipv4_addr_to_string pcb.id.dest_ip) pcb.id.dest_port;
    let window = Tcp_window.rx_wnd pcb.wnd in
    let sequence = Tcp_window.tx_next pcb.wnd in
    let ack_number = Tcp_window.rx_next pcb.wnd in
    packet t pcb.id (fun env ->
      Mpl.Tcp.t ~rst:1 ~ack:1 ~sequence ~ack_number
        ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
        ~window ~data:`None ~options:`None env
    )

  (* Output an RST when we dont have a PCB *)
  let rst_no_pcb ~sequence ~ack_number t id = 
    printf "TCP: xmit RST no pcb -> %s:%d\n%!"
      (ipv4_addr_to_string id.dest_ip) id.dest_port;
    packet t id (fun env ->
      Mpl.Tcp.t ~rst:1 ~ack:1 ~sequence ~ack_number
        ~source_port:id.local_port ~dest_port:id.dest_port
        ~window:0 ~data:`None ~options:`None env
    )

  (* Output a SYN ACK packet *)
  let syn_ack t pcb =
    printf "TCP: xmit SYN_ACK -> %s:%d\n%!"
      (ipv4_addr_to_string pcb.id.dest_ip) pcb.id.dest_port;
    let window = Tcp_window.rx_wnd pcb.wnd in
    let sequence = Tcp_window.tx_next pcb.wnd in
    let ack_number = Tcp_window.rx_next pcb.wnd in
    packet t pcb.id (fun env ->
      Mpl.Tcp.t ~syn:1 ~ack:1 ~sequence ~ack_number
        ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
        ~window ~data:`None ~options:`None env
    )

  (* Transmit a single TCP segment *)
  let segment t chan seg =
    let { pcb; txq; txc } = chan in
    let fin = if Tcp_segment.Tx.fin seg then
      (Tcp_window.tx_fin pcb.wnd; 1) else 0 in
    Tcp_window.ack_send pcb.wnd;
    let window = Tcp_window.rx_wnd pcb.wnd in
    let sequence = Tcp_window.tx_next pcb.wnd in
    let ack_number = Tcp_window.rx_next pcb.wnd in
    let data = Tcp_segment.Tx.data seg in
    let urg = if Tcp_segment.Tx.urg seg then 1 else 0 in
    packet t pcb.id (fun env ->
      Mpl.Tcp.t ~ack:1 ~fin ~urg ~sequence ~ack_number
        ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
        ~window ~data ~options:`None env
    )

  (* Test if our side has closed the connection *)
  let closed chan = chan.tx_closed

  (* Close our (transmit) side of the connection *)
  let close chan =
    printf "TCP: tx_close\n%!";
    (* No state transition here until our tx queue is
       flushed and the FIN is sent. The tx queue will reject
       any further additions after this. Repeated close
       on the same channel is fine. *)
    chan.tx_closed <- true

  (* Process the transmit queue for a PCB *)
  let rec output t chan =
    let { pcb; txq; txc } = chan in
    let tx_mss = Tcp_window.tx_mss pcb.wnd in
    let seg, waiting = Tcp_segment.Tx.output tx_mss pcb.txsegs in
    pcb.txsegs <- waiting;
    match seg with
    |Some seg ->
      let seg =
        (* If this is the last data segment and the TX channel
           is closed, then mark the segment with a FIN flag before
           transmitting it *)
      if (closed chan) && (Tcp_segment.Tx.is_empty waiting) then (
        printf "TCP: process_output, sending FIN\n%!";
        Tcp_segment.Tx.with_fin seg)
      else seg in
      segment t chan seg >>
      output t chan
    |None -> begin
      (* If the transmit channel is closed and we haven't already
         sent a FIN, do so now *)
      let ack = Tcp_window.ack_needed pcb.wnd in
      let fin = 
        if chan.tx_closed then begin
          match pcb.state with
          (* These all indicate we have already sent a FIN *)
          |Fin_wait_1 |Fin_wait_2 |Closing
          |Last_ack |Time_wait |Closed -> false
          |Established -> pcb.state <- Fin_wait_1; true
          |Close_wait -> pcb.state <- Closing; true
          |Syn_received |Syn_sent |Listen -> printf "TCP: output odd state\n%!"; false
        end else false in
       (* If we need either, then construct a new tx segment *)
       if fin || ack then
         segment t chan (Tcp_segment.Tx.seg ~fin `None)
       else
         return ()
    end
end

module Rx = struct

  (* Test if the other side has closed the connection *)
  let closed chan =
    match chan.pcb.state with
    |Close_wait 
    |Closing -> true
    |_ -> false

  (* Queue the data in a received packet up *)
  let input chan (tcp:Mpl.Tcp.o) =
    let {pcb; rxq; rxc} = chan in
    match Tcp_window.valid pcb.wnd tcp#sequence with
    |true ->
      (* Wrap the incoming segment in a segment type *)
      let seg = Tcp_segment.Rx.seg tcp in
      (* Coalesce any outstanding segments *)
      let rcv_nxt = Tcp_window.rx_next pcb.wnd in
      let ready, waiting = Tcp_segment.Rx.input
        ~rcv_nxt ~segs:pcb.rxsegs ~seg in
      (* Update PCB with any remaining outstanding segments *)
      pcb.rxsegs <- waiting;
      (* Add the views to the receive queue, 
         and advance rx seq. It will be acked from the 
         transmit queue processor (so acks can be delayed). *)
      Tcp_segment.Rx.iter (fun p ->
        let _ = Lwt_sequence.add_r p rxq in
        Tcp_window.rx_advance pcb.wnd (OS.Istring.View.length p);
      ) ready;
      Lwt_condition.signal rxc ();
      (* Check if there is an incoming FIN to close the connection *)
      if tcp#fin = 1 then begin
        printf "TCP: transitioning to Close_wait\n%!";
        Tcp_window.rx_fin pcb.wnd;
        chan.pcb.state <- Close_wait;
      end;
      true
    |false ->
      printf "TCP: bad sequence number, ignoring\n%!"; 
      false
end

(* TODO: start and stop timer on the tx condition var *) 
let rec output_timer t ch = 
  OS.Time.sleep 0.05 >>
  Tx.output t ch >>
  output_timer t ch

(* Queue some data for transmission *)
let tx_queue chan output =
  failwith "todo"

(* Process an incoming TCP packet that has an active PCB *)
let process_input t ip tcp (chan,_) =
  match chan.pcb.state with
  |Syn_received -> begin
     match tcp#ack = 1 && (Rx.input chan tcp) with
     |true ->
        (* ack number was good, so connection is established *)
        printf "TCP: connection established\n%!";
        chan.pcb.state <- Established;
        return ()
     |false ->
        (* invalid sequence number, send back an RST *)
        printf "TCP: invalid SYN, sending RST\n";
        Tx.rst t chan.pcb
     end
  |Established |Close_wait |Closing -> begin
     match Rx.input chan tcp with
     |true ->
        printf "TCP: received packet\n%!";
        return ()
     |false ->
        printf "TCP: out of window TCP segment, ignoring\n%!";
        return ()
  end
  |_ ->
    printf "Unknown PCB state: %s\n%!" (string_of_state chan.pcb.state);
    return ()

(* Helper function to apply function with contents of hashtbl, or take default action *)
let with_hashtbl h k fn default =
  try fn (Hashtbl.find h k) with Not_found -> default k

let new_connection t ip tcp id =
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
        let rxsegs = Tcp_segment.Rx.empty in
        let txsegs = Tcp_segment.Tx.empty in
        (* Construct basic PCB in Syn_received state *)
        let state = Syn_received in
        let pcb = { state; rxsegs; txsegs; wnd; id } in
        (* Add the PCB to our connection table *)
        Hashtbl.add t.channels id (listener pcb);
        (* Reply with SYN ACK *)
        Tx.syn_ack t pcb;
      )
      (* Send a TCP RST since we dont have a listener *)
      (fun source_port ->
         let sequence = 0l in
         let ack_number = Int32.succ tcp#sequence in
         Tx.rst_no_pcb ~sequence ~ack_number t id
      )
  |false -> (* Got an older SYN ACK perhaps, discard it *)
    printf "TCP: discarding unknown TCP packet\n%!";
    return ()

(* Main input function for TCP packets *)
let input t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) =
  (* Construct a connection ID from the input packet *)
  let dest_ip = ipv4_addr_of_uint32 ip#src in
  let dest_port = tcp#source_port in
  let local_ip = Ipv4.get_ip t.ip in
  let local_port = tcp#dest_port in
  let id = { dest_port; dest_ip; local_ip; local_port } in
  (* Lookup connection from the active PCB hash *)
  with_hashtbl t.channels id
    (* PCB exists, so continue the connection state machine in tcp_input *)
    (process_input t ip tcp)
    (* No existing PCB, so check if it is a SYN for a listening function *)
    (new_connection t ip tcp)

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


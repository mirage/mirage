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
exception Assert_failure of string

module State = struct

  type i = [
    | `Listen
    | `Rx_fin
    | `Rx_fin_ack
    | `Syn_acked
    | `Syn_received
    | `Syn_sent
    | `Timeout
    | `Tx_close
    | `Tx_fin 
  ]

  type t =
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

  exception Bad_transition of (t * i)
  exception Bad_state of t * string

  let to_string = function
    |Closed -> "Closed"
    |Listen -> "Listen"
    |Syn_sent -> "Syn_sent"
    |Syn_received -> "Syn_received"
    |Established -> "Established"
    |Fin_wait_1 -> "Fin_wait_1"
    |Fin_wait_2 -> "Fin_wait_2"
    |Close_wait -> "Close_wait"
    |Closing -> "Closing"
    |Last_ack -> "Last_ack"
    |Time_wait -> "Time_wait"

  let i_to_string (i:i) =
    match i with
    | `Listen -> "listen"
    | `Rx_fin -> "rx_fin"
    | `Rx_fin_ack -> "rx_fin_ack"
    | `Syn_acked -> "syn_acked"
    | `Syn_received -> "syn_received"
    | `Syn_sent -> "syn_sent"
    | `Timeout -> "timeout"
    | `Tx_close -> "tx_close"
    | `Tx_fin  -> "tx_fin"

  let tick t (i:i) =
    match t,i with
    |Closed,`Listen -> Listen
    |Listen,`Syn_received -> Syn_received
    |Syn_received, `Syn_sent -> Syn_received
    |Syn_received, `Syn_acked -> Established
    |Established, `Tx_fin -> Fin_wait_1
    |Established, `Rx_fin -> Close_wait 
    |Fin_wait_1, `Rx_fin_ack -> Fin_wait_2
    |Fin_wait_1, `Rx_fin -> Closing
    |Fin_wait_2, `Rx_fin -> Time_wait
    |Close_wait, `Tx_close -> Last_ack
    |Closing, `Rx_fin_ack -> Time_wait
    |Last_ack, `Rx_fin_ack -> Closed
    |Time_wait, `Timeout -> Closed
    |_ -> raise (Bad_transition (t,i))

  (* True if we have sent a fin indicating tx connection close *)
  let fin_sent = function
    |Listen 
    |Closed
    |Syn_sent
    |Syn_received
    |Established
    |Close_wait  -> false
    |Closing
    |Last_ack
    |Fin_wait_1
    |Fin_wait_2
    |Time_wait -> true

  (* True if we have received a fin indicating rx connection close *)
  let fin_received = function
    |Listen
    |Closed
    |Syn_sent
    |Syn_received
    |Established
    |Fin_wait_1
    |Fin_wait_2 -> false
    |Close_wait
    |Closing
    |Last_ack
    |Time_wait -> true

end

type id = {
  dest_port: int;        (* Remote TCP port *)
  dest_ip: ipv4_addr;    (* Remote IP address *)
  local_port: int;       (* Local TCP port *)
  local_ip: ipv4_addr;   (* Local IP address *)
}

type pcb = {
  id: id;
  wnd: Tcp_window.t;                      (* Window information *)
  mutable state: State.t;                 (* Connection state *)
  mutable rxsegs: Tcp_segment.Rx.seg_q;   (* Received segments queue *)
  mutable txsegs: Tcp_segment.Tx.seg_q;   (* Transmit segments queue *)
  mutable rtxsegs: Tcp_segment.Tx.xseg_q; (* Retransmit segments queue *)
  txsegs_cond: unit Lwt_condition.t;      (* Transmit wake up *)
  rtxsegs_cond: unit Lwt_condition.t;     (* Retransmit wake up *)
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

(* Advance the TCP state machine as an event happens *)
let tick pcb sc =
  try 
    let t = State.tick pcb.state sc in
    printf "TCP: tick %s from %s -> %s\n%!"
     (State.i_to_string sc) (State.to_string pcb.state) (State.to_string t);
    pcb.state <- t
  with State.Bad_transition (t,sc) -> 
    printf "TCP: bad statecall %s from %s\n%!" (State.i_to_string sc) (State.to_string pcb.state)

module Tx = struct

  (* Output a general TCP packet, checksum it, and if a reference is provided,
     also record the sent packet for retranmission purposes *)
  let packet ?memo t id (fn: view->Mpl.Tcp.o) =
    let src = ipv4_addr_to_uint32 (Ipv4.get_ip t.ip) in
    let tcpfn env = 
      let tcp = fn env in
      let dest_ip = ipv4_addr_to_uint32 id.dest_ip in
      let pseudo_header = Int32.(add (add src dest_ip) (of_int (6+tcp#sizeof))) in
      let checksum = OS.Istring.View.ones_complement_checksum tcp#env tcp#sizeof pseudo_header in
      tcp#set_checksum checksum;
      match memo with
      |Some m -> m := Some tcp
      |None -> ()
    in
    let ip_id = 30 in (* XXX TODO random *)
    let data = `Sub tcpfn in
    let ipfn env = Mpl.Ipv4.t ~src ~protocol:`TCP ~id:ip_id ~data env in
    Ipv4.output ~dest_ip:id.dest_ip t.ip ipfn >>
    return ()

  (* Output a RST control packet to reset a connection *) 
  let rst t pcb =
    printf "TCP: xmit RST -> %s:%d\n%!" (ipv4_addr_to_string pcb.id.dest_ip) pcb.id.dest_port;
    let window = Tcp_window.rx_wnd pcb.wnd in
    let sequence = Tcp_sequence.to_int32 (Tcp_window.tx_next pcb.wnd) in
    let ack_number = Tcp_sequence.to_int32 (Tcp_window.rx_next pcb.wnd) in
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

  (* Queue a SYN ACK segment for transmission *)
  let syn_ack t pcb =
    printf "TCP: xmit SYN_ACK -> %s:%d\n%!"
      (ipv4_addr_to_string pcb.id.dest_ip) pcb.id.dest_port;
    let ack = Some (Tcp_window.rx_next pcb.wnd) in
    let seg = Tcp_segment.Tx.seg ~syn:true ~ack `None in
    Tcp_segment.Tx.queue seg pcb.txsegs

(*
  (* Transmit a single TCP segment *)
  let segment t chan seg =
    let { pcb; txq; txc } = chan in
    let fin = if Tcp_segment.Tx.fin seg then
      (Tcp_window.tx_fin pcb.wnd; 1) else 0 in
    Tcp_window.ack_send pcb.wnd;
    let window = Tcp_window.rx_wnd pcb.wnd in
    let sequence = Tcp_sequence.to_int32 (Tcp_window.tx_next pcb.wnd) in
    let ack_number = Tcp_sequence.to_int32 (Tcp_window.rx_next pcb.wnd) in
    let data = Tcp_segment.Tx.data seg in
    let urg = if Tcp_segment.Tx.urg seg then 1 else 0 in
    packet t pcb.id (fun env ->
      Mpl.Tcp.t ~ack:1 ~fin ~urg ~sequence ~ack_number
        ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
        ~window ~data ~options:`None env
    )
*)

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
  let rec output t pcb =
    let tx_mss = Tcp_window.tx_mss pcb.wnd in (* TODO real MSS calc *)
    match Tcp_segment.Tx.coalesce tx_mss pcb.txsegs with
    |Some seg -> (* Transmit outstanding packet *)
       let window = Tcp_window.rx_wnd pcb.wnd in
       let sequence = Tcp_sequence.to_int32 (Tcp_window.tx_next pcb.wnd) in
       let data = Tcp_segment.Tx.data seg in
       let syn =
         if Tcp_segment.Tx.syn seg then
           (* signal a SYN is going out to the state machine *)
           (tick pcb `Syn_sent; 1)
         else 0 in
       let fin = if Tcp_segment.Tx.fin seg then 1 else 0 in
       let ack, ack_number = match Tcp_segment.Tx.ack seg with
         |Some ack_number -> 1, (Tcp_sequence.to_int32 ack_number)
         |None -> 0, 0l in
       packet t pcb.id (fun env ->
         Mpl.Tcp.t ~ack ~syn ~fin ~sequence ~ack_number
           ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
           ~window ~data ~options:`None env
       ) >>
       output t pcb
    |None -> (* Wait for something to wake up the transmit queue *)
      Lwt_condition.wait pcb.txsegs_cond >>
      output t pcb
    
(*
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
        if chan.tx_closed && (not (State.fin_sent pcb.state)) then begin
          tick chan `Tx_close;
          true
        end else false in
       (* If we need either, then construct a new tx segment *)
       if fin || ack then
         segment t chan (Tcp_segment.Tx.seg ~fin `None)
       else
         return ()
    end

*)
end

module Rx = struct

  (* Test if the other side has closed the connection *)
  let closed {pcb} =
    State.fin_received pcb.state

  (* Queue the data in a received packet up *)
  let queue chan (tcp:Mpl.Tcp.o) =
    let {pcb; rxq; rxc} = chan in
    (* Wrap the incoming segment in a segment type *)
    let seg = Tcp_segment.Rx.seg tcp in
    (* Coalesce any outstanding segments and retrieve any ready buffers *)
    let bufs = Tcp_segment.Rx.input ~wnd:pcb.wnd ~seg pcb.rxsegs in
    (* Add the views to the receive queue for the application *)
    Tcp_segment.Rx.(iter (fun seg -> ignore(Lwt_sequence.add_r (view seg) rxq)) bufs);
    Lwt_condition.signal rxc ()

  (* Process an incoming TCP packet that has an active PCB *)
  let input t ip tcp (chan,_) =
    (* Wrap packet into an Rx segment *)
    let seg = Tcp_segment.Rx.seg tcp in
    queue chan tcp;
    match chan.pcb.state with 
    |State.Syn_sent ->
      if Tcp_segment.Rx.syn seg then 
        tick chan.pcb `Syn_received;
      raise_lwt (Not_implemented "input: syn_sent")
    |State.Syn_received ->
      printf "Syn_received input\n%!";
      return ()
    | _ ->
      raise_lwt (Not_implemented "input: unknown state")
(*
    match chan.pcb.state with
    |State.Syn_received -> begin
       match tcp#ack = 1 && (queue chan tcp) with
       |true ->
        printf "TCP: connection established\n%!";
        chan.pcb.state <- State.Established;
        return ()
     |false ->
        (* invalid sequence number, send back an RST *)
        printf "TCP: invalid SYN, sending RST\n";
        Tx.rst t chan.pcb
     end
  |State.Established -> begin
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
*)

end

(* TODO: start and stop timer on the tx condition var *) 
let rec output_timer t ch = 
  OS.Time.sleep 0.05 >>
  Tx.output t ch >>
  output_timer t ch

(* Queue some data for transmission *)
let tx_queue chan output =
  failwith "todo"

(* Helper function to apply function with contents of hashtbl, or take default action *)
let with_hashtbl h k fn default =
  try fn (Hashtbl.find h k) with Not_found -> default k

let new_connection t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) id =
  match (tcp#syn = 1) && (tcp#ack = 0) with
  |true -> (* This is a pure SYN, no ACK packet *)
    (* Try to find a listener *)
    with_hashtbl t.listeners id.local_port
    (* Got a listener, construct new PCB and send ACK *)
      (fun listener ->
        (* Set up the windowing variables *)
        let rxsegs = Tcp_segment.Rx.seg_q () in
        let txsegs = Tcp_segment.Tx.seg_q () in
        let rtxsegs = Tcp_segment.Tx.xseg_q () in
        let txsegs_cond = Lwt_condition.create () in
        let rtxsegs_cond = Lwt_condition.create () in
        let wnd = Tcp_window.t ~ack:(Tcp_segment.Tx.mark_ack rtxsegs) in
        let isn = Tcp_sequence.of_int32 tcp#sequence in
        Tcp_window.rx_open wnd ~rcv_wnd:tcp#window ~isn;
        (* Construct basic PCB in Syn_received state *)
        let state = State.Listen in
        let pcb = { state; rxsegs; txsegs; rtxsegs;
          txsegs_cond; rtxsegs_cond; wnd; id } in
        tick pcb `Syn_received;
        (* Add the PCB to our connection table *)
        Hashtbl.add t.channels id (listener pcb);
        (* Queue a SYN ACK for transmission *)
        Tx.syn_ack t pcb
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
    (Rx.input t ip tcp)
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


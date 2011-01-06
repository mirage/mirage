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

type id = {
  dest_port: int;               (* Remote TCP port *)
  dest_ip: ipv4_addr;           (* Remote IP address *)
  local_port: int;              (* Local TCP port *)
  local_ip: ipv4_addr;          (* Local IP address *)
}

type pcb = {
  id: id;
  wnd: Tcp_window.t;            (* Window information *)
  rxq: Tcp_segment.Rx.q;        (* Received segments queue *)
  txq: Tcp_segment.Tx.q;        (* Transmit segments queue *)
  rtxq: Tcp_segment.Rtx.q;      (* Retransmit segments queue *)
  txc: unit Lwt_condition.t;    (* Transmit wake up that queue is non-empty *)
  rtxc: int Lwt_condition.t;    (* Retransmit wake up that window space is free *)
  ack: Tcp_ack.Delayed.t;       (* Ack state *)
  ackc: unit Lwt_condition.t;   (* Ack wake up *)
  mutable state: Tcp_state.t;   (* Connection state *)
}

type t = {
  ip : Ipv4.t;
  channels: (id, (pcb * unit Lwt.t)) Hashtbl.t ;
  listeners: (int, (pcb -> unit Lwt.t)) Hashtbl.t ;
}

(* Advance the TCP state machine as an event happens *)
let tick pcb sc =
  let open Tcp_state in
  try 
    let t = tick pcb.state sc in
    printf "TCP: tick %s from %s -> %s\n%!" (i_to_string sc) (to_string pcb.state) (to_string t);
    pcb.state <- t
  with Bad_transition (t,sc) -> printf "TCP: bad statecall %s from %s\n%!"
    (i_to_string sc) (to_string pcb.state)

module Tx = struct

  (* Queue a segment for transmission *)
  let queue_segment pcb seg =
    Tcp_segment.Tx.queue seg pcb.txq >>
    return (Lwt_condition.signal pcb.txc ())

  (* Queue some data for transmission *)
  let queue pcb data =
    let seg = Tcp_segment.Tx.seg data in
    queue_segment pcb seg

  (* Output a general TCP packet, checksum it, and if a reference is provided,
     also record the sent packet for retranmission purposes *)
  let packet ?memo t id (fn:OS.Istring.View.t->Mpl.Tcp.o) =
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

  (* Output an RST when we dont have a PCB *)
  let rst_no_pcb ~sequence ~ack_number t id = 
    printf "TCP: transmit RST no pcb -> %s:%d\n%!"
      (ipv4_addr_to_string id.dest_ip) id.dest_port;
    packet t id (fun env ->
      Mpl.Tcp.t ~rst:1 ~ack:1 ~sequence ~ack_number
        ~source_port:id.local_port ~dest_port:id.dest_port
        ~window:0 ~data:`None ~options:`None env
    )

  (* Process the transmit queue for a PCB *)
  let rec output t pcb =
    let {wnd} = pcb in
    let tx_mss = Tcp_window.tx_mss pcb.wnd in (* TODO real MSS calc *)
    match Tcp_segment.Tx.coalesce tx_mss pcb.txq with
    |Some seg -> (* Transmit outstanding packet *)
       let window = Tcp_window.tx_wnd pcb.wnd in
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
       let memo = ref None in
       printf "TCP.Tx.output: transmitting packet to wire\n%!";
       packet ~memo t pcb.id (fun env ->
         Mpl.Tcp.t ~ack ~syn ~fin ~sequence ~ack_number
           ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
           ~window ~data ~options:`None env
       ) >>
       (match !memo with 
        |None -> return ()
        |Some p -> 
          let xseg = Tcp_segment.Rtx.seg p in
          Tcp_segment.Rtx.queue ~wnd xseg pcb.rtxq
       ) >>
       output t pcb
    |None -> (* Wait for something to wake up the transmit queue *)
      Lwt_condition.wait pcb.txc >>
      output t pcb
   
   (* Thread to listen for ACKs and transmit them directly *)
   let rec ack_thread t pcb =
     let {wnd} = pcb in
     lwt seq = Lwt_condition.wait pcb.ackc in
     let ack_number = Tcp_sequence.to_int32 (Tcp_window.rx_next wnd) in
     let sequence = Tcp_sequence.to_int32 (Tcp_window.tx_next wnd) in
     let window = Tcp_window.tx_wnd wnd in
     printf "TCP.Tx.ack_thread: sending empty ACK %lu\n%!" ack_number;
     packet t pcb.id (fun env ->
       Mpl.Tcp.t ~ack:1 ~sequence ~ack_number 
         ~source_port:pcb.id.local_port ~dest_port:pcb.id.dest_port
         ~window ~data:`None ~options:`None env
     ) >>
     (Tcp_ack.Delayed.transmit pcb.ack (Tcp_window.rx_next wnd);
     ack_thread t pcb)
end

module Rx = struct

  (* Process an incoming TCP packet that has an active PCB *)
  let input t ip tcp (pcb,_) =
    let {wnd; rxq} = pcb in
    (* Wrap packet into an Rx segment *)
    let seg = Tcp_segment.Rx.seg tcp in
    (* Coalesce any outstanding segments and retrieve ready segments *)
    let segs = Tcp_segment.Rx.input ~wnd ~seg rxq in
    match pcb.state with 
    |Tcp_state.Syn_sent ->
      (* TODO: RFC793 pg66 *)
      raise_lwt (Not_implemented "input: syn_sent")
    |Tcp_state.Syn_received -> begin
      printf "Syn_received input\n%!";
      return ()
    end
    |Tcp_state.Closed ->
      printf "TCP: discarding segment for closed pcb\n%!";
      return ()
    | _ ->
      raise_lwt (Not_implemented "input: unknown state")
end

(* Helper function to apply function with contents of hashtbl, or take default action *)
let with_hashtbl h k fn default =
  try fn (Hashtbl.find h k) with Not_found -> default k

let new_connection t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) id listener =
  (* Set up the windowing variables *)
  let rxq = Tcp_segment.Rx.q () in
  let txq = Tcp_segment.Tx.q () in
  let rtxq = Tcp_segment.Rtx.q () in
  let txc = Lwt_condition.create () in
  let rtxc = Lwt_condition.create () in
  let ackc = Lwt_condition.create () in
  
  let isn = Tcp_sequence.of_int32 tcp#sequence in
  let ack = Tcp_ack.Delayed.t ackc isn in

  (* Construct window handler *)
  let wnd = Tcp_window.t
    ~tx:(Tcp_segment.Rtx.mark_ack rtxc rtxq) 
    ~rx:(Tcp_ack.Delayed.receive ack) in

  Tcp_window.rx_open wnd ~rcv_wnd:tcp#window ~isn;
  (* Construct ACK handers *)
  (* Construct basic PCB in Syn_received state *)
  let state = Tcp_state.Listen in
  let pcb = { state; rxq; txq; rtxq;
    txc; rtxc; wnd; id; ack; ackc } in
  tick pcb `Syn_received;
  (* Compose the overall thread from the various tx/rx threads
     and the main listener function *)
  let th =
    listener pcb <?>
    (Tx.output t pcb) <?>
    (Tx.ack_thread t pcb) 
  in
  (* Add the PCB to our connection table *)
  Hashtbl.add t.channels id (pcb, th);
  (* Queue a SYN ACK for transmission *)
  let ack = Some (Tcp_window.rx_next pcb.wnd) in
  Tx.queue_segment pcb (Tcp_segment.Tx.seg ~syn:true ~ack `None)

let input_no_pcb t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) id =
  match tcp#rst = 1 with
  |true ->
    (* Incoming RST should be ignored, RFC793 pg65 *)
    return ()
  |false -> begin
    match tcp#ack = 1 with
    |true ->
       (* ACK to a listen socket results in an RST with
          <SEQ=SEG.ACK><CTL=RST> RFC793 pg65 *)
       let sequence = tcp#ack_number in
       let ack_number = 0l in
       Tx.rst_no_pcb ~sequence ~ack_number t id
    |false -> begin
       (* Check for a SYN, RFC793 pg65 *)
       match tcp#syn = 1 with
       |true ->
         (* Try to find a listener *)
         with_hashtbl t.listeners id.local_port
           (new_connection t ip tcp id)
           (fun source_port ->
             let sequence = 0l in
             let ack_number = Int32.succ tcp#sequence in
             Tx.rst_no_pcb ~sequence ~ack_number t id
           )
       |false ->
         (* What the hell is this packet? No SYN,ACK,RST *)
         return ()
    end
  end

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
    (input_no_pcb t ip tcp)

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


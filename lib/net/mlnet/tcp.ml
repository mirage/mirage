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
exception Closed

type id = {
  dest_port: int;               (* Remote TCP port *)
  dest_ip: ipv4_addr;           (* Remote IP address *)
  local_port: int;              (* Local TCP port *)
  local_ip: ipv4_addr;          (* Local IP address *)
}

type pcb = {
  id: id;
  wnd: Tcp_window.t;            (* Window information *)
  rxq: Tcp_segment.Rx.q;        (* Received segments queue for out-of-order data *)
  txq: Tcp_segment.Tx.q;        (* Transmit segments queue *)
  ack: Tcp_ack.Delayed.t;       (* Ack state *)
  state: Tcp_state.t;           (* Connection state *)
  urx: OS.Istring.View.t list option Lwt_mvar.t;
}

type t = {
  ip : Ipv4.t;
  channels: (id, (pcb * unit Lwt.t)) Hashtbl.t ;
  listeners: (int, (pcb -> unit Lwt.t)) Hashtbl.t ;
}

module Tx = struct

  (* Output a general TCP packet, checksum it, and if a reference is provided,
     also record the sent packet for retranmission purposes *)
  let rec xmit ip id ~flags ~rx_ack ~seq ~window data =
    (* Construct TCP closure *)
    let memo = ref None in
    let src = ipv4_addr_to_uint32 (Ipv4.get_ip ip) in
    let rst = match flags with Tcp_segment.Tx.Rst -> 1 |_ -> 0 in
    let syn = match flags with Tcp_segment.Tx.Syn -> 1 |_ -> 0 in
    let fin = match flags with Tcp_segment.Tx.Fin -> 1 |_ -> 0 in
    let ack = match rx_ack with Some _ -> 1 |None -> 0 in
    let ack_number = match rx_ack with Some n -> Tcp_sequence.to_int32 n |None -> 0l in
    let sequence = Tcp_sequence.to_int32 seq in
    let options = `None in
    let source_port = id.local_port in
    let {dest_port; dest_ip} = id in
    let tcpfn env = 
      let tcp = Mpl.Tcp.t ~syn ~fin ~rst ~ack ~ack_number
        ~sequence ~source_port ~dest_port ~window ~data ~options env in
      let dest_ip = ipv4_addr_to_uint32 dest_ip in
      let pseudo_header = Int32.(add (add src dest_ip) (of_int (6+tcp#sizeof))) in
      let checksum = OS.Istring.View.ones_complement_checksum tcp#env tcp#sizeof pseudo_header in
      tcp#set_checksum checksum;
      memo := Some tcp
    in
    (* Construct IP closure *)
    let ip_id = 30 in (* XXX TODO random *)
    let data = `Sub tcpfn in
    let ipfn env = Mpl.Ipv4.t ~src ~protocol:`TCP ~id:ip_id ~data env in
    Ipv4.output ~dest_ip:id.dest_ip ip ipfn >>
    match !memo with
    |Some x -> 
      return x#data_sub_view
    |None -> 
      printf "TCP.Tx.xmit: failed, retrying\n%!";
      OS.Time.sleep 0.01 >>
      xmit ip id ~flags ~rx_ack ~seq ~window data

  (* Output an RST when we dont have a PCB *)
  let rst_no_pcb ~seq ~ack_number t id = 
    printf "TCP: transmit RST no pcb -> %s:%d\n%!"
      (ipv4_addr_to_string id.dest_ip) id.dest_port;
    let window = 0 in
    let data = `None in
    xmit t.ip id ~flags:Tcp_segment.Tx.Rst ~rx_ack:ack_number ~seq ~window data >>
    return ()

  (* Queue up an immediate close segment *)
  let close pcb =
    let open Tcp_state in
    match tx pcb.state with
    |Established ->
      tick_tx pcb.state `fin;
      Tcp_segment.Tx.(output ~flags:Fin pcb.txq `None)
    |_ -> return ()
     
  (* Thread that transmits ACKs in response to received packets,
      thus telling the other side that more can be sent *)
  let rec thread t pcb ~send_ack ~rx_ack  =
    let {wnd; ack} = pcb in
    let rec send () =
      lwt ack_number = Lwt_mvar.take send_ack in
      let rx_ack = Some ack_number in
      let seq = Tcp_window.tx_nxt wnd in
      let window = Tcp_window.tx_wnd wnd in
      let flags = Tcp_segment.Tx.No_flags in
      printf "TCP.Tx.ack_thread: sending empty ACK\n%!";
      xmit t.ip pcb.id ~flags ~rx_ack ~seq ~window `None >>
      Tcp_ack.Delayed.transmit ack ack_number >>
      send () in
    let rec notify () =
      lwt ack_number = Lwt_mvar.take rx_ack in
      Tcp_ack.Delayed.transmit ack ack_number >>
      notify () in
    send () <&> (notify ())

end

module Rx = struct

  (* Process an incoming TCP packet that has an active PCB *)
  let input t ip tcp (pcb,_) =
    let {rxq} = pcb in
    (* Coalesce any outstanding segments and retrieve ready segments *)
    Tcp_segment.Rx.input rxq tcp
   
  (* Thread that spools the data into an application receive buffer,
     and notifies the ACK subsystem that new data is here *)
  let rec thread pcb ~rx_data =
    let {wnd; ack; urx} = pcb in
    lwt data = Lwt_mvar.take rx_data in
    printf "Tcp.RX.thread: received\n%!";
    Tcp_ack.Delayed.receive ack (Tcp_window.rx_nxt wnd) >>
    (match data with
    |None ->
      Tcp_state.tick_rx pcb.state `fin;
      Lwt_mvar.put urx None
    |Some data ->
      List.iter (fun x -> 
       printf "%s\n%!" (OS.Istring.(Prettyprint.hexdump (View.to_string x 0 (View.length x))))) data;
      Lwt_mvar.put urx (Some data)
    ) >>
    thread pcb ~rx_data 
        
end

(* Helper function to apply function with contents of hashtbl, or take default action *)
let with_hashtbl h k fn default =
  try fn (Hashtbl.find h k) with Not_found -> default k

let new_connection t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) id listener =
  (* Set up the windowing variables *)
  let wnd = Tcp_window.t () in
  (* When we transmit an ACK for a received segment, rx_ack is written to *)
  let rx_ack = Lwt_mvar.create_empty () in
  (* When we receive an ACK for a transmitted segment, tx_ack is written to *)
  let tx_ack = Lwt_mvar.create_empty () in
  (* When new data is received, rx_data is written to *)
  let rx_data = Lwt_mvar.create_empty () in
  (* Write to this mvar to transmit an empty ACK to the remote side *) 
  let send_ack = Lwt_mvar.create_empty () in
  (* The user application receive mvar TODO make it a parqueue *)
  let urx = Lwt_mvar.create_empty () in
  (* Set up transmit and receive queues *)
  let txq, tx_t = Tcp_segment.Tx.q ~xmit:(Tx.xmit t.ip id) ~wnd ~rx_ack ~tx_ack in
  let rxq = Tcp_segment.Rx.q ~rx_data ~wnd ~tx_ack in
  (* Set up ACK module *)
  let rx_isn = Tcp_sequence.of_int32 tcp#sequence in
  let ack = Tcp_ack.Delayed.t ~send_ack ~last:rx_isn in
  (* Mark receive window as open since we got a SYN *)
  Tcp_window.rx_open wnd ~rcv_wnd:tcp#window ~isn:rx_isn;
  (* Construct basic PCB in Syn_received state *)
  let state = Tcp_state.t () in
  let pcb = { state; rxq; txq; wnd; id; ack; urx } in
  Tcp_state.tick_rx pcb.state `syn;
  (* Compose the overall thread from the various tx/rx threads
     and the main listener function *)
  let th =
    listener pcb <?>
    (Tx.thread t pcb ~send_ack ~rx_ack) <?>
    (Rx.thread pcb ~rx_data) in
  (* Add the PCB to our connection table *)
  Hashtbl.add t.channels id (pcb, th);
  (* Queue a SYN ACK for transmission *)
  Tcp_state.tick_tx pcb.state `syn;
  Tcp_segment.Tx.output ~flags:Tcp_segment.Tx.Syn txq `None

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
       let seq = Tcp_sequence.of_int32 tcp#ack_number in
       let ack_number = None in
       Tx.rst_no_pcb ~seq ~ack_number t id
    |false -> begin
       (* Check for a SYN, RFC793 pg65 *)
       match tcp#syn = 1 with
       |true ->
         (* Try to find a listener *)
         with_hashtbl t.listeners id.local_port
           (new_connection t ip tcp id)
           (fun source_port ->
             let seq = Tcp_sequence.of_int32 0l in
             let ack_number = Some (Tcp_sequence.(incr (of_int32 tcp#sequence))) in
             Tx.rst_no_pcb ~seq ~ack_number t id
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

(* Blocking read on a PCB, with None returned if the connection
   is closed.
   TODO: make this a queue so we can advertise window *)
let rec read pcb =
  Lwt_mvar.take pcb.urx

(* Block until both sides of the connection are closed *)
let close pcb =
  Tx.close pcb
  (* TODO thread to block on Rx close happening *)
     
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


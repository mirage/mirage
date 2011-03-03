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

type id = {
  dest_port: int;               (* Remote TCP port *)
  dest_ip: ipv4_addr;           (* Remote IP address *)
  local_port: int;              (* Local TCP port *)
  local_ip: ipv4_addr;          (* Local IP address *)
}

type pcb = {
  id: id;
  wnd: Window.t;            (* Window information *)
  rxq: Segment.Rx.q;        (* Received segments queue for out-of-order data *)
  txq: Segment.Tx.q;        (* Transmit segments queue *)
  ack: Ack.Delayed.t;       (* Ack state *)
  state: State.t;           (* Connection state *)
  urx: User_buffer.Rx.t;         (* App rx buffer *)
  urx_close_t: unit Lwt.t;      (* App rx close thread *)
  urx_close_u: unit Lwt.u;      (* App rx connection close wakener *)
  utx: User_buffer.Tx.t;         (* App tx buffer *)
}

type t = {
  ip : Ipv4.t;
  channels: (id, (pcb * unit Lwt.t)) Hashtbl.t;
  listeners: (int, ((ipv4_addr * int) -> pcb -> unit Lwt.t)) Hashtbl.t;
}

module Tx = struct

  exception IO_error

  (* Output a general TCP packet, checksum it, and if a reference is provided,
     also record the sent packet for retranmission purposes *)
  let rec xmit ip id ~flags ~rx_ack ~seq ~window ~options data =
    (* Construct TCP closure *)
    let memo = ref None in
    let src = ipv4_addr_to_uint32 (Ipv4.get_ip ip) in
    let rst = match flags with Segment.Tx.Rst -> 1 |_ -> 0 in
    let syn = match flags with Segment.Tx.Syn -> 1 |_ -> 0 in
    let fin = match flags with Segment.Tx.Fin -> 1 |_ -> 0 in
    let ack = match rx_ack with Some _ -> 1 |None -> 0 in
    let ack_number = match rx_ack with Some n -> Sequence.to_int32 n |None -> 0l in
    let sequence = Sequence.to_int32 seq in
    let source_port = id.local_port in
    let options = `Sub (Options.marshal options) in
    let {dest_port; dest_ip} = id in
    let tcpfn env = 
      let tcp = Mpl.Tcp.t ~syn ~fin ~rst ~ack ~ack_number
        ~sequence ~source_port ~dest_port ~window ~data ~options env in
      let src_ip = ipv4_addr_to_bytes (Ipv4.get_ip ip) in
      let dest_ip = ipv4_addr_to_bytes dest_ip in
      let i32l x = Int32.of_int ((Char.code x.[0] lsl 8) + (Char.code x.[1])) in
      let i32r x = Int32.of_int ((Char.code x.[2] lsl 8) + (Char.code x.[3])) in
      let ph = Int32.of_int (6+tcp#sizeof) in
      let ph = Int32.add ph (i32l dest_ip) in
      let ph = Int32.add ph (i32r dest_ip) in
      let ph = Int32.add ph (i32l src_ip) in
      let ph = Int32.add ph (i32r src_ip) in
      let checksum = OS.Istring.View.ones_complement_checksum tcp#env tcp#sizeof ph in
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
      printf "TCP.Tx.xmit: failed\n%!";
      raise_lwt IO_error

  (* Output a TCP packet, and calculate some settings from a state descriptor *)
  let xmit_pcb ip id ~flags ~wnd ~options data =
    let window = Int32.to_int (Window.rx_wnd wnd) in (* TODO scaling *)
    let rx_ack = Some (Window.rx_nxt wnd) in
    let seq = Window.tx_nxt wnd in
    xmit ip id ~flags ~rx_ack ~seq ~window ~options data

  (* Output an RST when we dont have a PCB *)
  let rst_no_pcb ~seq ~rx_ack t id = 
    printf "TCP: transmit RST no pcb -> %s:%d\n%!"
      (ipv4_addr_to_string id.dest_ip) id.dest_port;
    let window = 0 in
    let options = [] in
    let data = `None in
    xmit t.ip id ~flags:Segment.Tx.Rst ~rx_ack ~seq ~window ~options data >>
    return ()

  (* Queue up an immediate close segment *)
  let close pcb =
    let open State in
    match tx pcb.state with
    |Established ->
      tick_tx pcb.state `fin;
      Segment.Tx.(output ~flags:Fin pcb.txq `None)
    |_ -> return ()
     
  (* Thread that transmits ACKs in response to received packets,
     thus telling the other side that more can be sent, and
     also data from the user transmit queue *)
  let rec thread t pcb ~send_ack ~rx_ack  =
    let {wnd; ack} = pcb in


    (* Transmit an empty ack when prompted by the Ack thread *)
    let rec send_empty_ack () =
      lwt ack_number = Lwt_mvar.take send_ack in
      let flags = Segment.Tx.No_flags in
      printf "TCP.Tx.ack_thread: sending empty ACK\n%!";
      let options = [] in
      xmit_pcb t.ip pcb.id ~flags ~wnd ~options `None >>
      Ack.Delayed.transmit ack ack_number >>
      send_empty_ack () in
    (* When something transmits an ACK, tell the delayed ACK thread *)
    let rec notify () =
      lwt ack_number = Lwt_mvar.take rx_ack in
      Ack.Delayed.transmit ack ack_number >>
      notify () in
    send_empty_ack () <&> (notify ())

end

module Rx = struct

  (* Process an incoming TCP packet that has an active PCB *)
  let input t ip tcp (pcb,_) =
    let {rxq} = pcb in
    (* Coalesce any outstanding segments and retrieve ready segments *)
    Segment.Rx.input rxq tcp
   
  (* Thread that spools the data into an application receive buffer,
     and notifies the ACK subsystem that new data is here *)
  let thread pcb ~rx_data =
    let {wnd; ack; urx; urx_close_u} = pcb in
    (* Thread to monitor application receive and pass it up *)
    let rec rx_application_t () =
      lwt data = Lwt_mvar.take rx_data in
      Ack.Delayed.receive ack (Window.rx_nxt wnd) >>
      match data with
      |None ->
        State.tick_rx pcb.state `fin;
        Lwt.wakeup urx_close_u ();
        rx_application_t ()
      |Some data ->
        let rec queue = function
        |hd::tl ->
           User_buffer.Rx.add_r urx hd >>
           queue tl
        |[] -> return () in
       queue data <&> (rx_application_t ())
    in   
    rx_application_t ()
end

module Wnd = struct

  let thread ~urx ~utx ~wnd ~tx_wnd_update =
    (* Monitor our advertised receive window, and update the
       PCB window when the application consumes data. *)
    let rx_window_mvar = Lwt_mvar.create_empty () in
    User_buffer.Rx.monitor urx rx_window_mvar;
    let rec rx_window_t () =
      lwt rx_cur_size = Lwt_mvar.take rx_window_mvar in
      let rx_wnd = max 0l (Int32.sub (User_buffer.Rx.max_size urx) rx_cur_size) in
      Window.set_rx_wnd wnd rx_wnd;
      (* TODO: kick the ack thread to send window update if it was 0 *)
      rx_window_t ()
    in
    (* Monitor our transmit window when updates are received remotely,
       and tell the application that new space is available when it is blocked *)
    let rec tx_window_t () =
      lwt tx_wnd = Lwt_mvar.take tx_wnd_update in
      User_buffer.Tx.free utx tx_wnd;
      tx_window_t ()
    in
    rx_window_t () <?> (tx_window_t ())
    
end

(* Helper function to apply function with contents of hashtbl, or take default action *)
let with_hashtbl h k fn default =
  try fn (Hashtbl.find h k) with Not_found -> default k

let new_connection t (ip:Mpl.Ipv4.o) (tcp:Mpl.Tcp.o) id listener =
  (* Set up the windowing variables *)
  let rx_wnd_scale = 0 in
  let tx_wnd_scale = 0 in
  let tx_wnd = tcp#window in
  let rx_wnd = 16384 in (* TODO: too small *)
  let rx_isn = Sequence.of_int32 tcp#sequence in
  let wnd = Window.t ~rx_wnd_scale ~tx_wnd_scale ~rx_wnd ~tx_wnd ~rx_isn in
  (* When we transmit an ACK for a received segment, rx_ack is written to *)
  let rx_ack = Lwt_mvar.create_empty () in
  (* When we receive an ACK for a transmitted segment, tx_ack is written to *)
  let tx_ack = Lwt_mvar.create_empty () in
  (* When new data is received, rx_data is written to *)
  let rx_data = Lwt_mvar.create_empty () in
  (* Write to this mvar to transmit an empty ACK to the remote side *) 
  let send_ack = Lwt_mvar.create_empty () in
  (* The user application receive buffer and close notification *)
  let urx = User_buffer.Rx.create ~max_size:16384l in (* TODO: too small, but useful for debugging *)
  let urx_close_t, urx_close_u = Lwt.task () in
  (* The user application transmit buffer *)
  let utx = User_buffer.Tx.create ~wnd in
  (* The window handling thread *)
  let tx_wnd_update = Lwt_mvar.create_empty () in
  (* Set up transmit and receive queues *)
  let txq, tx_t = Segment.Tx.q ~xmit:(Tx.xmit_pcb t.ip id) ~wnd ~rx_ack ~tx_ack in
  let rxq = Segment.Rx.q ~rx_data ~wnd ~tx_ack ~tx_wnd_update in
  (* Set up ACK module *)
  let ack = Ack.Delayed.t ~send_ack ~last:rx_isn in
  (* Construct basic PCB in Syn_received state *)
  let state = State.t () in
  let pcb = { state; rxq; txq; wnd; id; ack; urx; urx_close_t; urx_close_u; utx } in
  State.tick_rx pcb.state `syn;
  (* Compose the overall thread from the various tx/rx threads
     and the main listener function *)
  let th =
    let dst = (ipv4_addr_of_uint32 ip#src), tcp#source_port in
    listener dst pcb <?>
    (Tx.thread t pcb ~send_ack ~rx_ack) <?>
    (Rx.thread pcb ~rx_data) <?>
    (Wnd.thread ~utx ~urx ~wnd ~tx_wnd_update)
  in
  (* Add the PCB to our connection table *)
  Hashtbl.add t.channels id (pcb, th);
  (* Queue a SYN ACK for transmission *)
  State.tick_tx pcb.state `syn;
  Segment.Tx.output ~flags:Segment.Tx.Syn txq `None

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
       let seq = Sequence.of_int32 tcp#ack_number in
       let rx_ack = None in
       Tx.rst_no_pcb ~seq ~rx_ack t id
    |false -> begin
       (* Check for a SYN, RFC793 pg65 *)
       match tcp#syn = 1 with
       |true ->
         (* Try to find a listener *)
         with_hashtbl t.listeners id.local_port
           (new_connection t ip tcp id)
           (fun source_port ->
             let seq = Sequence.of_int32 0l in
             let rx_ack = Some (Sequence.(incr (of_int32 tcp#sequence))) in
             Tx.rst_no_pcb ~seq ~rx_ack t id
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

(* Blocking read on a PCB *)
let rec read pcb =
  let data =
    lwt d = User_buffer.Rx.take_l pcb.urx in 
    return (Some d) in
  let closed =
    pcb.urx_close_t >>
    return None in
  data <?> closed

(* Maximum allowed write *)
let write_available pcb =
  min 1300 (Int32.to_int (User_buffer.Tx.available pcb.utx))

(* Wait for more write space *)
let write_wait_for pcb sz =
  User_buffer.Tx.wait_for pcb.utx (Int32.of_int sz)

(* Write a segment *)
let write pcb data =
  Segment.Tx.output pcb.txq data

(* Block until both sides of the connection are closed *)
let close pcb =
  Tx.close pcb
  (* TODO thread to block on Rx close happening *)
     
(* Register a TCP listener on a port *)
let listen t port fn =
  let th,_ = Lwt.task () in
  if Hashtbl.mem t.listeners port then
    printf "WARNING: TCP listen port %d already used\n%!" port;
  Hashtbl.replace t.listeners port fn;
  th

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


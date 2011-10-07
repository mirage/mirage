(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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
  ack: Ack.Immediate.t;       (* Ack state *)
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

  let checksum ~src ~dst pkt =
    let src = ipv4_addr_to_uint32 src in
    let dst = ipv4_addr_to_uint32 dst in
    let len = (List.fold_left (fun a b -> Bitstring.bitstring_length b + a) 0 pkt) / 8 in
    let pseudo_header = BITSTRING { src:32; dst:32; 0:8; 6:8; len:16 } in
    Checksum.ones_complement_list (pseudo_header :: pkt)

  (* Output a general TCP packet, checksum it, and if a reference is provided,
     also record the sent packet for retranmission purposes *)
  let xmit ip id ~flags ~rx_ack ~seq ~window ~options data =
    let {dest_port; dest_ip; local_port; local_ip} = id in
    let rst = flags = Segment.Tx.Rst in
    let syn = flags = Segment.Tx.Syn in
    let fin = flags = Segment.Tx.Fin in
    let ack = match rx_ack with Some _ -> true |None -> false in
    let ack_number = match rx_ack with Some n -> Sequence.to_int32 n |None -> 0l in
    let sequence = Sequence.to_int32 seq in
    printf "TCP xmit: dest_ip=%s %s%s%s%sseq=%lu ack=%lu\n%!" (ipv4_addr_to_string dest_ip)
      (if rst then "RST " else "") (if syn then "SYN " else "")
      (if fin then "FIN " else "") (if ack then "ACK " else "") sequence ack_number; 
    let options = Options.marshal options in
    let data_offset = (Bitstring.bitstring_length options + 160) / 32 in
    let header = BITSTRING {
      local_port:16; dest_port:16; sequence:32; ack_number:32; 
      data_offset:4; 0:6; false:1; ack:1; false:1; rst:1; syn:1; fin:1; window:16; 
      0:16; 0:16 } in
    let frame = [header;options;data] in
    let checksum = checksum ~src:local_ip ~dst:dest_ip frame in
    let checksum_bs,_,_ = BITSTRING { checksum:16 } in
    let header_buf,_,_ = header in
    header_buf.[16] <- checksum_bs.[0];
    header_buf.[17] <- checksum_bs.[1];
    Ipv4.output ip ~proto:`TCP ~dest_ip frame >>
    return frame

  (* Output a TCP packet, and calculate some settings from a state descriptor *)
  let xmit_pcb ip id ~flags ~wnd ~options ~override_seq data =
    let window = Int32.to_int (Window.rx_wnd wnd) in (* TODO scaling *)
    let rx_ack = Some (Window.rx_nxt wnd) in
    let seq = match override_seq with
             | None -> Window.tx_nxt wnd
             | Some s -> s
    in
    xmit ip id ~flags ~rx_ack ~seq ~window ~options data

  (* Output an RST when we dont have a PCB *)
  let rst_no_pcb ~seq ~rx_ack t id = 
    let window = 0 in
    let options = [] in
    let data = "",0,0 in
    xmit t.ip id ~flags:Segment.Tx.Rst ~rx_ack ~seq ~window ~options data >>
    return ()

  (* Queue up an immediate close segment *)
  let close pcb =
    let open State in
    match tx pcb.state with
    |Established ->
      tick_tx pcb.state `fin;
      let data = "",0,0 in
      Segment.Tx.(output ~flags:Fin pcb.txq data)
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
      let options = [] in
      let data = "",0,0 in
      let override_seq = None in
      xmit_pcb t.ip pcb.id ~flags ~wnd ~options ~override_seq data >>
      Ack.Immediate.transmit ack ack_number >>
      send_empty_ack () in
    (* When something transmits an ACK, tell the delayed ACK thread *)
    let rec notify () =
      lwt ack_number = Lwt_mvar.take rx_ack in
      Ack.Immediate.transmit ack ack_number >>
      notify () in
    send_empty_ack () <&> (notify ())

end

module Rx = struct

  (* Process an incoming TCP packet that has an active PCB *)
  let input t pkt (pcb,_) =
    bitmatch pkt with
    | { sequence:32:bind(Sequence.of_int32 sequence);
        ack_number:32:bind(Sequence.of_int32 ack_number); 
        data_offset:4:bind(data_offset * 32); _:6;
        urg:1; ack:1; psh:1; rst:1; syn:1; fin:1; window:16; 
        checksum: 16; urg_ptr: 16; options:data_offset-160:bitstring;
        data:-1:bitstring } ->
          let _ = Options.of_packet options in
          let seg = Segment.Rx.make ~sequence ~fin ~syn ~ack ~ack_number ~window ~data in
          let {rxq} = pcb in
          (* Coalesce any outstanding segments and retrieve ready segments *)
          Segment.Rx.input rxq seg
    | { _ } -> return (printf "RX.input: unknown\n%!")
   
  (* Thread that spools the data into an application receive buffer,
     and notifies the ACK subsystem that new data is here *)
  let thread pcb ~rx_data =
    let {wnd; ack; urx; urx_close_u} = pcb in
    (* Thread to monitor application receive and pass it up *)
    let rec rx_application_t () =
      lwt data = Lwt_mvar.take rx_data in
      match data with
      |None ->
        lwt _ = Ack.Immediate.receive ack (Window.rx_nxt wnd) in
        State.tick_rx pcb.state `fin;
        Lwt.wakeup urx_close_u ();
        rx_application_t ()
      |Some data ->
        lwt _ = match data with
        | [] -> return () 
        | _ -> Ack.Immediate.receive ack (Window.rx_nxt wnd)
        in
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

let new_connection t ~window ~sequence ~options id data listener =
  (* Set up the windowing variables *)
  let rx_wnd_scale = 0 in
  let tx_wnd_scale = 0 in
  let tx_wnd = window in
  let rx_wnd = 16384 in (* TODO: too small *)
  let rx_isn = Sequence.of_int32 sequence in
  let options = Options.of_packet options in
  let tx_mss = List.fold_left (fun a -> function Options.MSS m -> Some m |_ -> a) None options in
  (* Initialise the window handler *)
  let wnd = Window.t ~rx_wnd_scale ~tx_wnd_scale ~rx_wnd ~tx_wnd ~rx_isn ~tx_mss in
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
  let txq, tx_t = Segment.Tx.q ~xmit:(Tx.xmit_pcb t.ip id) ~wnd ~rx_ack ~tx_ack ~tx_wnd_update in
  let rxq = Segment.Rx.q ~rx_data ~wnd ~tx_ack in
  (* Set up ACK module *)
  let ack = Ack.Immediate.t ~send_ack ~last:(Sequence.incr rx_isn) in
  (* Construct basic PCB in Syn_received state *)
  let state = State.t () in
  let pcb = { state; rxq; txq; wnd; id; ack; urx; urx_close_t; urx_close_u; utx } in
  State.tick_rx pcb.state `syn;
  (* Compose the overall thread from the various tx/rx threads
     and the main listener function *)
  let th =
    let dst = id.dest_ip, id.dest_port in
    listener dst pcb <?>
    (Tx.thread t pcb ~send_ack ~rx_ack) <?>
    (Rx.thread pcb ~rx_data) <?>
    (Wnd.thread ~utx ~urx ~wnd ~tx_wnd_update)
  in
  (* Add the PCB to our connection table *)
  Hashtbl.add t.channels id (pcb, th);
  (* Queue a SYN ACK for transmission *)
  State.tick_tx pcb.state `syn;
  Segment.Tx.output ~flags:Segment.Tx.Syn txq ("",0,0)

let input_no_pcb t pkt id =
  bitmatch pkt with
  | { sequence:32; ack_number:32; 
      data_offset:4:bind(data_offset * 32); _:6;
      urg:1; ack:1; psh:1; rst:1; syn:1; fin:1; window:16; 
      checksum: 16; urg_ptr: 16; options:data_offset-160:bitstring;
      data:-1:bitstring } ->
    match rst with
    |true ->
      (* Incoming RST should be ignored, RFC793 pg65 *)
      return ()
    |false -> begin
      match ack with
      |true ->
         (* ACK to a listen socket results in an RST with
            <SEQ=SEG.ACK><CTL=RST> RFC793 pg65 *)
         let seq = Sequence.of_int32 ack_number in
         let rx_ack = None in
         Tx.rst_no_pcb ~seq ~rx_ack t id
      |false -> begin
         (* Check for a SYN, RFC793 pg65 *)
         match syn with
         |true ->
           (* Try to find a listener *)
           with_hashtbl t.listeners id.local_port
             (new_connection t ~window ~sequence ~options id data)
             (fun source_port ->
               let seq = Sequence.of_int32 0l in
               let rx_ack = Some (Sequence.(incr (of_int32 sequence))) in
               Tx.rst_no_pcb ~seq ~rx_ack t id
             )
         |false ->
           (* What the hell is this packet? No SYN,ACK,RST *)
           return ()
      end
    end

(* Main input function for TCP packets *)
let input t ~src ~dst data =
  bitmatch data with
  | { source_port:16; dest_port:16; pkt:-1:bitstring } ->
        let id = { local_port=dest_port; dest_ip=src; local_ip=dst; dest_port=source_port } in
        (* Lookup connection from the active PCB hash *)
        with_hashtbl t.channels id
          (* PCB exists, so continue the connection state machine in tcp_input *)
           (Rx.input t pkt)
          (* No existing PCB, so check if it is a SYN for a listening function *)
           (input_no_pcb t pkt)
  | { _ } -> 
        return (printf "TCP: input, unknown header, dropping\n%!")

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
  (* Our effective outgoing MTU is what can fit in a page *)
  min 4000 (min (Window.tx_mss pcb.wnd)
    (Int32.to_int (User_buffer.Tx.available pcb.utx)))

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


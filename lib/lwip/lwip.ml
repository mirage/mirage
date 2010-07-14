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

type ipv4_addr = int * int * int * int

(** Must be called before any other LWIP functions *)
external lwip_init: unit -> unit = "caml_lwip_init"

module Netif = struct
    (** Type of a network interface instance *)
    type t

    (** Create a new network interface with given IP, netmask and gateway *)
    external init: ip:ipv4_addr -> netmask:ipv4_addr -> gw:ipv4_addr -> t = "caml_netif_new"

    (** Set the network interface as the default one to use for source packets *)
    external set_default: t -> unit = "caml_netif_set_default"

    (** Mark the interface as being active *)
    external set_up: t -> unit = "caml_netif_set_up"

    (** Select for packets on the interface. XXX: interface will likely change *)
    external select: t -> int = "caml_netif_select"
   
    (** Helper function to construct a network interface *)
    let create ?(default=true) ?(up=true) ~ip ~netmask ~gw () =
         let netif = init ~ip ~netmask ~gw in
         if default then set_default netif;
         if up then set_up netif;
         netif
    
    (** Close a netif *)
    external close: t -> unit = "caml_netif_close"
end

open Lwt

(** LWIP requires regular timer functions to be called to process
    TCP, IP and ARP requests. This module constructs LWT threads
    which take care of these. *)
module Timer = struct

    external timer_tcp: unit -> unit = "caml_timer_tcp"
    external timer_ip_reass: unit -> unit = "caml_timer_ip_reass"
    external timer_etharp: unit -> unit = "caml_timer_etharp"

    (** TCP timer, every 100ms *)
    let rec tcp () =
        lwt () = Lwt_mirage.sleep 0.1 in
        timer_tcp ();
        tcp ()

    (** IP fragment reassembly timer, every 1sec *)
    let rec ip () = 
        lwt () = Lwt_mirage.sleep 1. in
        timer_ip_reass ();
        ip ()

    (** Ethernet ARP cache timer, every 5sec *)
    let rec etharp () = 
        lwt () = Lwt_mirage.sleep 5. in
        timer_etharp ();
        etharp ()

    (** Start all timers as LWT threads 
      * @return list of LWT threads of the spawned timers
      *)
    let start () =
        [ tcp (); ip (); etharp () ]
end

module TCP = struct

    exception Connection_closed
    let _ = Callback.register "TCP.Connection_closed" Connection_closed

    type pcb
    external tcp_new: unit -> pcb = "caml_tcp_new"
    external tcp_bind: pcb -> ipv4_addr -> int -> unit = "caml_tcp_bind"
    external tcp_listen: pcb -> (pcb -> unit) -> unit = "caml_tcp_listen"
    external tcp_accepted: pcb -> unit = "caml_tcp_accepted"
    external tcp_set_state: pcb -> 'a -> unit = "caml_tcp_set_state"
    external tcp_get_state: pcb -> 'a = "caml_tcp_get_state"
    external tcp_recved: pcb -> int -> unit = "caml_tcp_recved"
    external tcp_read: pcb -> string = "caml_tcp_read"
    external tcp_read_len: pcb -> int = "caml_tcp_read_len"
    external tcp_write: pcb -> string -> int -> int -> int = "caml_tcp_write"
    external tcp_sndbuf: pcb -> int = "caml_tcp_sndbuf"
    external tcp_close: pcb -> bool = "caml_tcp_close"
    external tcp_abort: pcb -> unit = "caml_tcp_abort"

    (** State descriptor for a single TCP connection.
        Has condition variables which are notified when events
        occur on transmit or receive, to unblock threads waiting 
        on those operations.
        The order of rx_notify/tx_notify below is important, as the
        C bindings address the fields directly.
      *)
    type state = {
        rx_notify: unit -> unit;
        tx_notify: unit -> unit;
        rx_cond: unit Lwt_condition.t;
        tx_cond: unit Lwt_condition.t;
    }

    let accept_cb listen_q listen_cond pcb =
        listen_q := pcb :: !listen_q;
        let rx_cond = Lwt_condition.create () in
        let tx_cond = Lwt_condition.create () in
        let rx_notify () = Lwt_condition.signal rx_cond () in
        let tx_notify () = Lwt_condition.signal tx_cond () in
        tcp_set_state pcb { 
            rx_cond = rx_cond; tx_cond = tx_cond;
            rx_notify = rx_notify; tx_notify = tx_notify };
        Lwt_condition.signal listen_cond ()

    let rec listen_forever listen_q listen_cond pcb connection_fn =
        (* the listen q gets filled with new connections *)
        lwt () = 
            if List.length !listen_q = 0 then
            Lwt_condition.wait listen_cond
        else
            return () in
        (* be careful with the listen q here as no locking, so musnt
           call into lwip too early, with connection_fn will likely do *)
        let rec spawn_threads acc =
            match !listen_q with
            | [] -> acc
            | hd :: tl ->
                listen_q := tl;
                tcp_accepted hd;
                let t = connection_fn hd in
                spawn_threads (t :: acc)
        in
        let accepts = spawn_threads [] in
        let listener = listen_forever listen_q listen_cond pcb connection_fn in
        Lwt.join (listener :: accepts)

     (** Listen for incoming TCP connections, and spawn a thread with the 
         [acceptfn] function for every new one. *)
     let listen acceptfn pcb =
         (* Queue of listening connections to spawn TCP threads for *)
         let listen_q = ref [] in
         (* Condition variable for LWIP to notify our accept callback *)
         let listen_cond = Lwt_condition.create () in
         tcp_listen pcb (accept_cb listen_q listen_cond);
         (* spawn a listening thread with the accept callback function *)
         listen_forever listen_q listen_cond pcb acceptfn

     (** Construct a new TCP listening socket bound to an IP and port 
       * @return TCP listening socket *)
     let bind ip port = 
         let pcb = tcp_new () in
         tcp_bind pcb ip port;
         pcb
    
     let rec read pcb =
         match tcp_read_len pcb with
         | -1 -> fail Connection_closed
         |  0 -> 
             let state = tcp_get_state pcb in
             lwt () = Lwt_condition.wait state.rx_cond in
             read pcb
         |  n -> return (tcp_read pcb)

     let rec internal_write pcb buf off len acc =
         let sndbuf = tcp_sndbuf pcb in
         let state = tcp_get_state pcb in
         if len > sndbuf then (
             match tcp_write pcb buf off sndbuf with
             | -1 -> 
                  Lwt_condition.wait state.tx_cond >>
                  internal_write pcb buf off len acc
             | written ->
                  (* wait for a write ack, then continue writing *)
                  Lwt_condition.wait state.tx_cond >>
                  internal_write pcb buf (off+written) (len-written) (acc+written)
         ) else (
             match tcp_write pcb buf off len with
             | -1 -> 
                  Lwt_condition.wait state.tx_cond >>
                  internal_write pcb buf off len acc
             | written -> return (acc+written)
         )         
        
     let write pcb buf = 
         internal_write pcb buf 0 (String.length buf) 0
       
     let close pcb =
         let rec fn = function
         | 0 -> 
             return (tcp_abort pcb)
         | n -> 
             if tcp_close pcb then
                 return ()
             else (
                 lwt () = Lwt.pause () in
                 fn (n-1)
             ) in
         fn 3
end

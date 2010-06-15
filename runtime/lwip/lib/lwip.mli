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
external lwip_init : unit -> unit = "caml_lwip_init"

module Netif : sig
    (** Type of a network interface instance *)
    type t

    (** Helper function to construct a network interface *)
    val create :
      ?default:bool ->
      ?up:bool ->
      ip:ipv4_addr -> netmask:ipv4_addr -> gw:ipv4_addr -> unit -> t
  end

(** LWIP requires regular timer functions to be called to process
    TCP, IP and ARP requests. This module constructs LWT threads
    which take care of these *)
module Timer : sig
    (** Start all timers as LWT threads 
      * @return list of LWT threads of the spawned timers
      *)
    val start : Netif.t -> 'a Lwt.t list
  end

module TCP : sig
    exception Connection_closed
    type pcb
    val listen : (pcb -> unit Lwt.t) -> pcb -> unit Lwt.t
    val bind : ipv4_addr -> int -> pcb
    val read : pcb -> string Lwt.t
    val write : pcb -> string -> int Lwt.t

    (** close TCP connection and invalidate the PCB. Any subsequent
        attempt to use the PCB will raise a Connection_closed exception.
        Will retry the close 3 times automatically, and abort the connection
        if all the attempts fail. *)
    val close : pcb -> unit Lwt.t 
  end

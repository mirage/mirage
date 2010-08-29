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
 *
 *)
open Lwt

(* Module type for an ethernet interface provided by the OS *)
module type ETHIF = sig
  type t
  type id
  val enumerate : unit -> id list Lwt.t
  val create : id -> t Lwt.t
  val destroy : t -> unit Lwt.t
  val input : t -> (Mpl.Ethernet.o -> unit Lwt.t) -> unit Lwt.t
  val output : t -> Mpl.Ethernet.x -> unit Lwt.t
  val mac : t -> string
end

(* Module to go higher up the stack (e.g. ARP and IPv4 *)
module type UP = sig
  type t
  type id
  val create: id -> (t * unit Lwt.t) Lwt.t
  val input : t -> unit Lwt.t
  val output : t -> Mpl.Ethernet.x -> unit Lwt.t
  val attach :
    t ->
      [ `ARP of Mpl.Ethernet.ARP.o -> unit Lwt.t
      | `IPv4 of Mpl.Ipv4.o -> unit Lwt.t
      | `IPv6 of Mpl.Ethernet.IPv4.o -> unit Lwt.t ] ->
          unit
  val detach : t -> [`ARP |`IPv4 |`IPv6 ] -> unit
  val mac : t -> Mlnet_types.ethernet_mac
end

(* Functorize across the hardware interface, to route packets
   appropriately *)
module Ethernet(IF:ETHIF) = struct 

  type t = {
    ethif: IF.t;
    mac: Mlnet_types.ethernet_mac;
    mutable arp: (Mpl.Ethernet.ARP.o -> unit Lwt.t);
    mutable ipv4: (Mpl.Ipv4.o -> unit Lwt.t);
    mutable ipv6: (Mpl.Ethernet.IPv4.o -> unit Lwt.t);
  }

  type id = IF.id

  (* Block on input on the interface and route any packets up stack *) 
  let input t =
    IF.input t.ethif (function
      |`ARP arp -> t.arp arp
      |`IPv4 ipv4 -> t.ipv4 (Mpl.Ipv4.unmarshal ipv4#data_env)
      |`IPv6 ipv6 -> t.ipv6 ipv6
    ) 

  let output t e =
    IF.output t.ethif e

  (* Listen until our shutdown thread is cancelled, then exit *)
  let listen t th =
    let rec loop () = input t >> loop () in
    loop () <?> th

  let create id = 
    lwt ethif = IF.create id in

    let arp = (fun _ -> return (print_endline "dropped arp")) in
    let ipv4 = (fun _ -> return (print_endline "dropped ipv4")) in
    let ipv6 = (fun _ -> return (print_endline "dropped ipv6")) in
    let mac = Mlnet_types.ethernet_mac_of_bytes (IF.mac ethif) in
    let t = { ethif; arp; ipv4; ipv6; mac }  in
    let th, _ =  Lwt.task () in
    let listen = listen t th in
    return (t, listen)
 
  let attach t = function
    |`ARP fn -> t.arp <- fn
    |`IPv4 fn -> t.ipv4 <- fn
    |`IPv6 fn -> t.ipv6 <- fn

  let detach t = function
    |`ARP -> t.arp <- (fun _ -> return ())
    |`IPv4 -> t.ipv4 <- (fun _ -> return ())
    |`IPv6 -> t.ipv6 <- (fun _ -> return ())

  let mac t = IF.mac t.ethif
  let enumerate = IF.enumerate

end

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
open Nettypes

type t = {
  ethif: OS.Netif.t;
  mac: ethernet_mac;
  mutable arp: (Mpl.Ethernet.ARP.o -> unit Lwt.t);
  mutable ipv4: (Mpl.Ipv4.o -> unit Lwt.t);
  mutable ipv6: (Mpl.Ethernet.IPv4.o -> unit Lwt.t);
}

(* Handle a single input frame, input as an istring view *)
let input t i = 
  try_lwt
    let x = Mpl.Ethernet.unmarshal i in 
    match x with
    | `ARP arp -> t.arp arp
    | `IPv4 ipv4 -> t.ipv4 (Mpl.Ipv4.unmarshal ipv4#data_sub_view)
    | `IPv6 ipv6 -> t.ipv6 ipv6
  with exn ->
    return ()

(* Loop and listen for frames *)
let rec listen t =
  OS.Netif.listen t.ethif (input t)

(* Output an istring view *)
let output t x =
  OS.Netif.output t.ethif (Mpl.Ethernet.m x)

let create ethif = 
  let arp = (fun _ -> return ()) in
  let ipv4 = (fun _ -> return ()) in
  let ipv6 = (fun _ -> return ()) in
  let mac = ethernet_mac_of_bytes (OS.Netif.mac ethif) in
  let t = { ethif; arp; ipv4; ipv6; mac } in
  let listen = listen t in
  (t, listen)
 
let attach t = function
  |`ARP fn -> t.arp <- fn
  |`IPv4 fn -> t.ipv4 <- fn
  |`IPv6 fn -> t.ipv6 <- fn

let detach t = function
  |`ARP -> t.arp <- (fun _ -> return ())
  |`IPv4 -> t.ipv4 <- (fun _ -> return ())
  |`IPv6 -> t.ipv6 <- (fun _ -> return ())

let mac t = t.mac
let enumerate = OS.Netif.enumerate

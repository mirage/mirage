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
  ethif: OS.Ethif.t;
  env_pool: string Lwt_pool.t;
  mac: ethernet_mac;
  mutable arp: (Mpl.Ethernet.ARP.o -> unit Lwt.t);
  mutable ipv4: (Mpl.Ipv4.o -> unit Lwt.t);
  mutable ipv6: (Mpl.Ethernet.IPv4.o -> unit Lwt.t);
  mutable active: bool;
}

(* Handle a single input frame *)
let input t sub = 
  Lwt_pool.use t.env_pool (fun buf ->
    let fillfn dstbuf dstoff len =
      OS.Hw_page.(read sub.page sub.off dstbuf dstoff sub.len);
      OS.Hw_page.(sub.len)
    in
    let env = Mpl.Mpl_stdlib.new_env ~fillfn buf in
    let x = Mpl.Ethernet.unmarshal env in 
    Mpl.Ethernet.prettyprint x;
    match x with
    | `ARP arp -> t.arp arp
    | `IPv4 ipv4 -> t.ipv4 (Mpl.Ipv4.unmarshal ipv4#data_env)
    | `IPv6 ipv6 -> t.ipv6 ipv6
  )

(* Loop and listen for frames *)
let rec listen t =
  OS.Ethif.listen t.ethif (input t)

(* TODO not zero copy yet *)
let output t frame =
  Lwt_pool.use t.env_pool (fun buf ->
    let env = Mpl.Mpl_stdlib.new_env buf in
    let sub = OS.Hw_page.alloc_sub () in
    let _ = Mpl.Ethernet.m frame env in
    let buf = Mpl.Mpl_stdlib.string_of_env env in
    let len = String.length buf in
    OS.Hw_page.write buf 0 sub.OS.Hw_page.page 0 len;
    let sub = { sub with OS.Hw_page.len=len } in
    OS.Ethif.output t.ethif sub
  )

let create id = 
  lwt ethif = OS.Ethif.create id in
  let arp = (fun _ -> return (print_endline "dropped arp")) in
  let ipv4 = (fun _ -> return (print_endline "dropped ipv4")) in
  let ipv6 = (fun _ -> return (print_endline "dropped ipv6")) in
  let mac = ethernet_mac_of_bytes (OS.Ethif.mac ethif) in
  let env_pool = Lwt_pool.create 5 (fun _ -> return (String.make 4096 '\000')) in
  let active = true in
  let t = { ethif; arp; ipv4; ipv6; mac; env_pool; active }  in
  let listen = listen t in
  return (t, listen)
 
let attach t = function
  |`ARP fn -> t.arp <- fn
  |`IPv4 fn -> t.ipv4 <- fn
  |`IPv6 fn -> t.ipv6 <- fn

let detach t = function
  |`ARP -> t.arp <- (fun _ -> return ())
  |`IPv4 -> t.ipv4 <- (fun _ -> return ())
  |`IPv6 -> t.ipv6 <- (fun _ -> return ())

let mac t = t.mac
let enumerate = OS.Ethif.enumerate

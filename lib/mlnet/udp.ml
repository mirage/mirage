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
open Mlnet_types
open Printf

module type UP = sig
  type t
  val input: t -> Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t
  val output: t -> dest_ip:ipv4_addr -> (Mpl.Mpl_stdlib.env -> unit) -> unit Lwt.t
  val listen: t -> int -> (Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t) -> unit
end

module UDP(IP:Ipv4.UP) = struct

  type t = {
    ip : IP.t;
    listeners: (int, (Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t)) Hashtbl.t
  }

  let input t ip udp =
    let dest_port = udp#dest_port in
    if Hashtbl.mem t.listeners dest_port then begin
      let fn = Hashtbl.find t.listeners dest_port in
      printf "UDP: routing to listener for port %d\n%!" dest_port;
      fn ip udp
    end else
      return ()

  (* UDP output needs the IPv4 header to generate the pseudo
     header for checksum calculation. Although we currently just
     set the checksum to 0 as it is optional *)
  let output t ~dest_ip udp =
    let dest = ipv4_addr_to_uint32 dest_ip in
    let src = ipv4_addr_to_uint32 (IP.get_ip t.ip) in
    let ipfn env =
      ignore(Mpl.Ipv4.t ~dest ~src ~protocol:`UDP ~checksum:0
      ~options:`None ~ttl:35 ~id:36 ~data:(`Sub udp) env) in
    IP.output t.ip ~dest_ip ipfn

  let listen t port fn =
    if Hashtbl.mem t.listeners port then
      printf "WARNING: UDP listen port %d already used\n%!" port;
    Hashtbl.replace t.listeners port fn

  let create ip =
    let listeners = Hashtbl.create 1 in
    let t = { ip; listeners } in
    IP.attach ip (`UDP (input t));
    t
end

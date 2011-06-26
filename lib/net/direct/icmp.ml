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
open Printf
open Nettypes

type t = {
  ip: Ipv4.t;
}

let input t src pkt =
  bitmatch pkt with
  |{0:8; code:8; csum:16; id:16; seq:16; data:-1:bitstring} -> (* echo reply *)
    return ()
  |{8:8; code:8; csum:16; id:16; seq:16; data:-1:bitstring} -> (* echo req *)
    let dest_ip = src in
    let csum = 0 in
    let reply = BITSTRING {
      0:8; code:8; csum:16; id:16; seq:16; data:-1:bitstring
    } in
    printf "Icmp.input: echo req -> reply\n%!";
    Ipv4.output t.ip ~proto:`ICMP ~dest_ip:src reply

let create ip =
  let t = { ip } in
  Ipv4.attach ip (`ICMP (input t));
  t

(* 
  |`EchoRequest icmp ->
    (* Create the ICMP echo reply *)
    let dest_ip = ipv4_addr_of_uint32 (Mpl.Ipv4.src ip) in
    let sequence = (Mpl.Icmp.EchoRequest.sequence icmp) in
    let identifier = (Mpl.Icmp.EchoRequest.identifier icmp) in
    let data = `Frag (Mpl.Icmp.EchoRequest.data_sub_view icmp) in
    let icmpfn env =
      let p = Mpl.Icmp.EchoReply.t ~identifier ~sequence ~data env in
      let csum = OS.Istring.(ones_complement_checksum env (Mpl.Icmp.EchoReply.sizeof p) 0l) in
      Mpl.Icmp.EchoReply.set_checksum p csum;
    in
    (* Create the IPv4 packet *)
    let id = Mpl.Ipv4.id ip in
    let src = Mpl.Ipv4.dest ip in
    let ipfn env = Mpl.Ipv4.t ~id ~protocol:`ICMP ~src ~data:(`Sub icmpfn) env in
    Ipv4.output t.ip ~dest_ip ipfn >> return ()
*)


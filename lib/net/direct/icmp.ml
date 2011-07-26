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
    return (printf "ICMP: discarding echo reply\n%!")
  |{8:8; code:8; csum:16; id:16; seq:16; data:-1:bitstring} -> (* echo req *)
    (* Adjust checksum for reply and transmit EchoReply *)
    let dest_ip = src in
    let csum = (csum + 0x0800) land 0xffff in
    let reply = BITSTRING { 0:8; code:8; csum:16; id:16; seq:16 } in
    Ipv4.output t.ip ~proto:`ICMP ~dest_ip:src [reply; data]

let create ip =
  let t = { ip } in
  Ipv4.attach ip (`ICMP (input t));
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun () ->
    printf "ICMP: shutting down\n%!";
    Ipv4.detach ip `ICMP;
  );
  t, th

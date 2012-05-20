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

cstruct icmpv4 {
  uint8_t ty;
  uint8_t code;
  uint16_t csum;
  uint16_t id;
  uint16_t seq
} as big_endian

type t = {
  ip: Ipv4.t;
}

let input t src hdr buf =
  match get_icmpv4_ty buf with
  |0 -> (* echo reply *)
    return (printf "ICMP: discarding echo reply\n%!")
  |8 -> (* echo request *)
    printf "echo request id %x seq %x\n%!" (get_icmpv4_id buf) (get_icmpv4_seq buf);
    let csum = (get_icmpv4_csum buf + 0x0800) land 0xffff in
    lwt dbuf = Ipv4.get_writebuf ~proto:`ICMP ~dest_ip:src t.ip in
    Cstruct.blit_buffer buf 0 dbuf 0 (Cstruct.len buf);
    set_icmpv4_ty dbuf 0;
    set_icmpv4_csum dbuf csum;
    let dbuf = Cstruct.sub dbuf 0 (Cstruct.len buf) in
    Ipv4.output t.ip dbuf
  |ty ->
    printf "ICMP unknown ty %d\n" ty; 
    return ()

let create ip =
  let t = { ip } in
  Ipv4.attach ip (`ICMP (input t));
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun () ->
    printf "ICMP: shutting down\n%!";
    Ipv4.detach ip `ICMP;
  );
  t, th

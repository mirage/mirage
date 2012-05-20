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
open Nettypes
open Printf

type t = {
  ip : Ipv4.t;
  listeners: (int, (src:ipv4_addr -> dst:ipv4_addr -> source_port:int -> OS.Io_page.t -> unit Lwt.t)) Hashtbl.t
}

cstruct udpv4 {
  uint16_t source_port;
  uint16_t dest_port;
  uint16_t length;
  uint16_t checksum
} as big_endian

let input t ~src ~dst buf =
  let dest_port = get_udpv4_dest_port buf in
  let data = Cstruct.sub buf sizeof_udpv4 (get_udpv4_length buf) in
  if Hashtbl.mem t.listeners dest_port then begin
    let fn = Hashtbl.find t.listeners dest_port in
    let source_port = get_udpv4_source_port buf in
    fn ~src ~dst ~source_port data
  end else
    return ()

(* UDP output needs the IPv4 header to generate the pseudo
   header for checksum calculation. Although we currently just
   set the checksum to 0 as it is optional *)
let get_writebuf ~dest_ip ~source_port ~dest_port t =
  lwt buf = Ipv4.get_writebuf ~proto:`UDP ~dest_ip t.ip in
  set_udpv4_source_port buf source_port;
  set_udpv4_dest_port buf dest_port;
  set_udpv4_checksum buf 0;
  let data = Cstruct.shift buf sizeof_udpv4 in
  return data

let output t buf =
  let len = Cstruct.len buf in
  let _ = Cstruct.shift_left buf sizeof_udpv4 in
  set_udpv4_length buf len;
  Ipv4.output t.ip buf

let listen t port fn =
  if Hashtbl.mem t.listeners port then
    fail (Failure "UDP port already bound")
  else begin
    let th, u = Lwt.task () in
    Hashtbl.add t.listeners port fn;
    Lwt.on_cancel th (fun _ -> Hashtbl.remove t.listeners port);
    th
  end

let create ip =
  let listeners = Hashtbl.create 1 in
  let t = { ip; listeners } in
  let thread,_ = Lwt.task () in
  Ipv4.attach ip (`UDP (input t));
  Lwt.on_cancel thread (fun () ->
    printf "UDP: thread shutdown\n%!";
    Ipv4.detach ip `UDP
  );
  t, thread

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
  listeners: (int, (Mpl.Ipv4.o -> Mpl.Udp.o -> unit Lwt.t)) Hashtbl.t
}

let input t ip udp =
  let dest_port = udp#dest_port in
  if Hashtbl.mem t.listeners dest_port then begin
    let fn = Hashtbl.find t.listeners dest_port in
    fn ip udp
  end else
    return ()

(* UDP output needs the IPv4 header to generate the pseudo
   header for checksum calculation. Although we currently just
   set the checksum to 0 as it is optional *)
let output t ~dest_ip udp =
  let src_ip = Ipv4.get_ip t.ip in
  let src = ipv4_addr_to_uint32 src_ip in
  let udpfn env =
    let p = udp env in
    let src_ip_i32 = ipv4_addr_to_uint32 src_ip in
    let dest_ip_i32 = ipv4_addr_to_uint32 dest_ip in
    let pseudo = Int32.(add (add src_ip_i32 dest_ip_i32) (of_int (17+p#total_length))) in
    let _csum = OS.Istring.View.ones_complement_checksum p#env p#sizeof pseudo in
    (* XXX off by one somewhere here? very odd - avsm *)
    (* p#set_checksum csum *)
    () in
  let ipfn env =
    Mpl.Ipv4.t ~src ~protocol:`UDP ~id:36 ~data:(`Sub udpfn) env in
  Ipv4.output t.ip ~dest_ip ipfn

let listen t port fn =
  if Hashtbl.mem t.listeners port then
    printf "WARNING: UDP listen port %d already used\n%!" port;
  Hashtbl.replace t.listeners port fn

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

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
open Printf
open Nettypes

type t = {
  ip: Ipv4.t;
}

let input t ip = function
  |`EchoRequest icmp ->
    (* Create the ICMP echo reply *)
    let dest_ip = ipv4_addr_of_uint32 ip#src in
    let sequence = icmp#sequence in
    let identifier = icmp#identifier in
    let data = `Frag icmp#data_sub_view in
    let icmpfn env =
      let p = Mpl.Icmp.EchoReply.t ~identifier ~sequence ~data env in
      let csum = OS.Istring.(ones_complement_checksum env p#sizeof 0l) in
      p#set_checksum csum;
    in
    (* Create the IPv4 packet *)
    let id = ip#id in 
    let src = ip#dest in
    let ipfn env = Mpl.Ipv4.t ~id ~protocol:`ICMP ~src ~data:(`Sub icmpfn) env in
    Ipv4.output t.ip ~dest_ip ipfn >> return ()

  |_ -> print_endline "dropped icmp"; return ()

let create ip =
  let thread,_ = Lwt.task () in
  let t = { ip } in
  Ipv4.attach ip (`ICMP (input t));
  Lwt.on_cancel thread (fun () ->
    printf "ICMP shutdown\n%!";
    Ipv4.detach ip `ICMP
  );
  printf "ICMP created\n%!";
  t, thread


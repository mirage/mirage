(*
 * Copyright (c) 2005-2011 Anil Madhavapeddy <anil@recoil.org>
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

module DL = Dnsloader
module DQ = Dnsquery
module DR = Dnsrr

let dnstrie = DL.(state.db.trie)

let log (addr,port) (dnsq:Packet.Questions.o) =
  printf "%.0f: %s %s %s (%s:%d)\n%!" (OS.Clock.time())
    (String.concat "." (Packet.Questions.qname dnsq))
    (Packet.Questions.qtype_to_string (Packet.Questions.qtype dnsq))
    (Packet.Questions.qclass_to_string (Packet.Questions.qclass dnsq))
    (Net.Nettypes.ipv4_addr_to_string addr) port

let get_answer qname qtype id env =
  let qname = List.map String.lowercase qname in  
  let ans = DQ.answer_query qname qtype dnstrie in
  let authoritative = if ans.DQ.aa then 1 else 0 in
  let questions = [Packet.Questions.t ~qname:qname ~qtype:qtype ~qclass:`IN] in
  let rcode = (ans.DQ.rcode :> Packet.rcode_t) in
  ignore(Packet.t ~qr:`Answer ~opcode:`Query ~truncation:0 ~rd:0 ~ra:0 ~id
    ~authoritative ~rcode ~questions
    ~answers:ans.DQ.answer ~authority:ans.DQ.authority
    ~additional:ans.DQ.additional env)

(* Space leaking hash table cache, always grows *)
module Leaking_cache = Hashtbl.Make (struct
    type t = string list * Packet.Questions.qtype_t
    let equal (a:t) (b:t) = a = b
    let hash = Hashtbl.hash
end)

let cache = Leaking_cache.create 1
let get_answer_memo qname qtype id =
  let qargs = qname, qtype in
  let view =
    try
      Leaking_cache.find cache qargs
    with Not_found -> begin
      let env = OS.Istring.Raw.alloc () in
      let view = OS.Istring.t env 0 in
      Mpl_dns_label.init_marshal view;
      get_answer qname qtype id view;
      Leaking_cache.add cache qargs view;
      view
    end in
  OS.Istring.set_uint16_be view 0 id;
  view

let no_memo mgr src dst env =
  Mpl_dns_label.init_unmarshal env;
  let d = Packet.unmarshal env in
  let q = (Packet.questions d).(0) in
  let renv = OS.Istring.Raw.alloc () in
  let rview = OS.Istring.t renv 0 in
  Mpl_dns_label.init_marshal rview;
  get_answer (Packet.Questions.qname q) (Packet.Questions.qtype q) (Packet.id d) rview;
  Net.Datagram.UDPv4.send mgr ~src dst rview

let leaky mgr src dst env =
  Mpl_dns_label.init_unmarshal env;
  let d = Packet.unmarshal env in
  let q = (Packet.questions d).(0) in
  let rview = get_answer_memo (Packet.Questions.qname q) (Packet.Questions.qtype q) (Packet.id d) in
  Net.Datagram.UDPv4.send mgr ~src dst rview

let listen ?(mode=`none) ~zonebuf mgr src =
  Dnsserver.load_zone [] zonebuf;
  Net.Datagram.UDPv4.(recv mgr src
    (match mode with
     |`none -> no_memo mgr src
     |`leaky -> leaky mgr src
    )
  )

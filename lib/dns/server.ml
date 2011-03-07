(*
 * Copyright (c) 2005-2010 Anil Madhavapeddy <anil@recoil.org>
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
    (String.concat "." dnsq#qname)
    (Packet.Questions.qtype_to_string dnsq#qtype)
    (Packet.Questions.qclass_to_string dnsq#qclass)
    (Net.Nettypes.ipv4_addr_to_string addr) port

let get_answer (qname,qtype) id =
  let qname = List.map String.lowercase qname in  
  let ans = DQ.answer_query qname qtype dnstrie in
  let authoritative = if ans.DQ.aa then 1 else 0 in
  let questions = [Packet.Questions.t ~qname:qname ~qtype:qtype ~qclass:`IN] in
  let rcode = (ans.DQ.rcode :> Packet.rcode_t) in
  Packet.t ~qr:`Answer ~opcode:`Query ~truncation:0 ~rd:0 ~ra:0 ~id
    ~authoritative ~rcode ~questions
    ~answers:ans.DQ.answer ~authority:ans.DQ.authority ~additional:ans.DQ.additional

let listen mgr src ~zonebuf =
  Dnsserver.load_zone [] zonebuf;
  Net.Datagram.UDPv4.(recv mgr src 
    (fun dst env ->
      Mpl_dns_label.init_unmarshal env;
      let d = Packet.unmarshal env in
      let q = d#questions.(0) in
      let r = get_answer (q#qname, q#qtype) d#id in
      let dnsfn env =
        Mpl_dns_label.init_marshal env;
        r env
      in
      let renv = OS.Istring.Raw.alloc () in
      let rview = OS.Istring.t renv 0 in
      ignore(dnsfn rview);
      send mgr ~src dst rview
    )
  )

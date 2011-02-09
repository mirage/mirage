(*
 * Copyright (c) 2005-2006 Tim Deegan <tjd@phlegethon.org>
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
 * dnsquery.mli -- map DNS query-response mechanism onto trie database
 *
 *)

type query_answer = {
  rcode : Packet.rcode_t;
  aa: bool;
  answer: (OS.Istring.View.t -> Packet.Answers.o) list;
  authority: (OS.Istring.View.t -> Packet.Authority.o) list;
  additional: (OS.Istring.View.t -> Packet.Additional.o) list;
}

val answer_query : string list -> 
  [> `A
   | `AAAA
   | `AFSDB
   | `ANY
   | `CNAME
   | `HINFO
   | `ISDN
   | `MAILB
   | `MB
   | `MG
   | `MINFO
   | `MR
   | `MX
   | `NS
   | `PTR
   | `RP
   | `RT
   | `SOA
   | `SRV
   | `TXT
   | `UNSPEC
   | `Unknown of int
   | `WKS
   | `X25 ] -> 
  Dnstrie.dnstrie -> query_answer

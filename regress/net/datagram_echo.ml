(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
 * Derived from code by Anil Madhavapeddy <anil@recoil.org>
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

let port = 55555

let main () =
  Log.info "Datagram_echo" "starting server";
  Net.(Manager.create (fun mgr interface id ->
    let loc = (None, port) in 
    Datagram.UDPv4.recv mgr loc
      (fun (rip,rpt) bits ->
        let s = Bitstring.string_of_bitstring bits in
        Log.info "Datagram_echo" "recv:%s:%d buf:\n%s"
          (Nettypes.ipv4_addr_to_string rip) rpt s;
        Datagram.UDPv4.send mgr ~src:loc (rip,rpt) bits
      )
  ))

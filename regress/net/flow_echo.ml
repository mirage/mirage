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

let rec echo (dip,dpt) flow  =
  Log.info "Flow_echo" "incoming: rem:%s:%d"
    (Net.Nettypes.ipv4_addr_to_string dip) dpt;

  match_lwt Net.Flow.read flow with
    | None
      -> return (
        Log.info "Flow_echo" "rem:%s:%d end"
          (Net.Nettypes.ipv4_addr_to_string dip) dpt;
      )
    | Some buf 
      -> (let s = Bitstring.string_of_bitstring buf in
          if s.[(String.length s) - 1] = '\x04' then (
            Log.info "Flow_echo" "rem:%s:%d buf:%s end"
              (Net.Nettypes.ipv4_addr_to_string dip) dpt s;
            Net.Flow.write flow buf 
            >> return ()
          ) else (
            Log.info "Flow_echo" "rem:%s:%d buf:\n%s"
              (Net.Nettypes.ipv4_addr_to_string dip) dpt s;
            Net.Flow.write flow buf 
            >> echo (dip,dpt) flow
          )
      )

let main () =
  Log.info "Flow_echo" "starting server";

  Net.Manager.create (fun mgr interface id ->
    Net.Flow.listen mgr (`TCPv4 ((None, port), echo))
    >> return (Log.info "Flow_echo" "done!")
  )

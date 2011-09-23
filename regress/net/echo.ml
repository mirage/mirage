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

let sp = Printf.sprintf
let port = 55555

let rec echo dst chan = 
  Log.info "Echo" "callback!";
  lwt more, buf = Net.Channel.read_until chan '\n' in
  let s = Bitstring.string_of_bitstring buf in

  Net.Channel.write_string chan (sp "%s\n" s)
  >> Net.Channel.flush chan
  >> (Log.info "Echo" "buf:%s" s;
      if more then echo dst chan else return(Log.info "Echo" "closed!")
  )

let main () =
  Log.info "Echo" "starting server";
  Net.Manager.create (fun mgr interface id ->
    Net.Channel.listen mgr (`TCPv4 ((None, port), echo))
    >> return (Log.info "Echo" "done")
  )

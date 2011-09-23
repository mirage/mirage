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

let rec echo (dip,dpt) chan = 
  Log.info "Echo" "callback!";

    (* doesn't seem to respect ^D closing the connection
  try_lwt
    lwt buf = Channel.read_crlf chan in
    Channel.write_bitstring chan buf
    >> (Log.info "Echo" "buf:%s" (Bitstring.string_of_bitstring buf);
        Channel.write_char chan '\n'
    )
    >> Channel.flush chan
    >> echo dst chan
  with Nettypes.Closed -> return (Log.info "Echo" "closed!")
    *)

  try_lwt
    lwt more, buf = Net.Channel.read_until chan '\n' in
    let s = Bitstring.string_of_bitstring buf in
    
    Net.Channel.write_string chan (sprintf "%s\n" s)
    >> Net.Channel.flush chan
    >> (Log.info "Echo"
          "rem:%s:%d buf:%s"
          (Net.Nettypes.ipv4_addr_to_string dip) dpt s;
      if more then echo (dip,dpt) chan 
      else
        return(Log.info "Echo" "closed!")
    )
  with Net.Nettypes.Closed -> return (Log.info "Echo" "closed!")

let main () =
  Log.info "Echo" "starting server";
  Net.Manager.create (fun mgr interface id ->
    (* no need to configure the interface *)
    Net.Channel.listen mgr (`TCPv4 ((None, port), echo))
    >> return (Log.info "Echo" "done!")
  )

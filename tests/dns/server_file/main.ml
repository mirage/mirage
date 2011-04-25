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

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
  lwt vbd_ids = OS.Blkif.enumerate () in
  lwt vbd, _ = match vbd_ids with |[x] -> OS.Blkif.create x |_ -> fail (Failure "1 vbd only") in
  lwt fs = Block.RO.create vbd in
  let zonefile = "openmirage.org.zone" in
  lwt zonebuf = Block.RO.read fs zonefile >>= OS.Istring.string_of_stream in
  let mode = `leaky in
  Dns.Server.listen ~mode ~zonebuf mgr (None, 53)

let _ = OS.Main.run (main ())


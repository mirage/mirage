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

let zonebuf = "
$ORIGIN www.openmirage.org. ;
$TTL    240
www.openmirage.org. 604800 IN SOA  (
        www.openmirage.org. anil.recoil.org.
        2010100401 ; serial
        3600 ; refresh
        1800 ; retry
        3024000 ; expire
        1800 ; minimum
)
        IN  NS     ns1.www.openmirage.org.
        IN  NS     ns2.www.openmirage.org.
ns1     IN  A      184.72.217.237
ns2     IN  A      204.236.217.197
@       IN  TXT    \"I wish I were a llama in Peru!\"
"

let rec watchdog () =
  let open Gc in
  Gc.compact ();
  let s = stat () in
  printf "blocks: l=%d f=%d\n%!" s.live_blocks s.free_blocks;
  OS.Time.sleep 2. >>
  watchdog ()

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
  let mode = `leaky in
  Dns.Server.listen ~mode ~zonebuf mgr (None, 53)

let _ = OS.Main.run (main ())


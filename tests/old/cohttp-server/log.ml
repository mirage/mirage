(*
 * Copyright (c) 2009 Anil Madhavapeddy <anil@recoil.org>
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

module Clock = OS.Clock

open Printf

type log_request = [
  |`Module of (string * string)
  |`Debug of string
]

let datetime () =
    let tm = Clock.gmtime (Clock.time ()) in
    Printf.sprintf "%.4d/%.2d/%.2d %.2d:%.2d:%.2d"
      (1900+tm.Clock.tm_year) tm.Clock.tm_mon
      tm.Clock.tm_mday tm.Clock.tm_hour tm.Clock.tm_min tm.Clock.tm_sec

let log_request = function
  |`Debug l -> printf "[%s] %s\n%!" (datetime ()) l;
  |`Module (m,l) -> printf "[%s] %.10s: %s\n%!" (datetime ()) m l

let logmod m fmt =
  let xfn f = log_request (`Module (m, f)) in
  kprintf xfn fmt

let logdbg fmt =
  let xfn f = log_request (`Debug f) in
  kprintf xfn fmt

(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

(* Flow library that uses the TCP/UDP Net library *)

open Lwt
open OS
open Nettypes

exception Not_implemented

type t

let connect t =
  fail Not_implemented 

let close t =
  return ()

let close_on_exit t fn =
  try_lwt
    lwt x = fn t in
    close t >>
    return x
  with exn ->
    close t >>
    fail exn

let read t =
   fail Not_implemented 

let write t view =
   fail Not_implemented 

let listen fn = function
  | TCP (addr, port) -> fail Not_implemented
  | UDP _ -> fail Not_implemented
  
let with_connection sockaddr fn =
  lwt t = connect sockaddr in
  close_on_exit t fn

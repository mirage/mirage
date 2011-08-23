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

(** A blocking (so not for heavy use) read-only filesystem interface. *)

open Lwt
open Printf
open OS.Socket

type t = Manager.interface

type file = unit

let create t = return t

exception Error of string

let read t filename =
  (* Open the FD using the manager bindings *)
  lwt fd = 
    match file_open_readonly filename with
    | OK fd -> return fd
    | Err x -> fail (Error x)
    | Retry -> assert false 
  in
  (* Construct a stream that reads pages of istrings *)
  return (Lwt_stream.from (fun () ->
    let str = String.create 4096 in
    lwt len = iobind (read fd str 0) 4096 in
    match len with
    | 0 -> return None
    | len -> return (Some (str, 0, len*8))
  ))

let iter_s t fn =
  match opendir "." with
  | Err x -> fail (Error x)
  | Retry -> assert false
  | OK dir -> begin
      let rec loop () =
        match readdir dir with
        |Err x -> return ()
        |Retry -> loop ()
        |OK fname -> fn fname >>= loop
      in
      try_lwt
        loop ()
      finally (match closedir dir with
        | Err x -> fail (Error x)
        | OK () -> return ()
        | Retry -> assert false)
  end

let size t name =
  match file_size name with
  | Err x -> fail (Error x)
  | Retry -> assert false
  | OK sz -> return sz

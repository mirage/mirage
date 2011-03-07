(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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

module Tap = struct
  type t = int
  external opendev: string -> t = "tap_opendev"
  external read: t -> Istring.Raw.t -> int -> int = "tap_read"
  external write: t -> Istring.Raw.t -> int -> unit = "tap_write"
end

type t = {
  id: string;
  dev: Tap.t;
  mutable active: bool;
  mac: string;
}

type id = string
exception Ethif_closed

(* We must generate a fake MAC for the Unix "VM", as using the
   tuntap one will cause all sorts of unfortunate MAC routing 
   loops in some stacks (notably Darwin tuntap). *)
let generate_local_mac () =
  let x = String.create 6 in
  let i () = Char.chr (Random.int 256) in
  (* set locally administered and unicast bits *)
  x.[0] <- Char.chr ((((Random.int 256) lor 2) lsr 1) lsl 1);
  x.[1] <- i ();
  x.[2] <- i ();
  x.[3] <- i ();
  x.[4] <- i ();
  x.[5] <- i ();
  x

let create (id:id) =
  let dev = Tap.opendev id in
  let mac = generate_local_mac () in
  let active = true in
  let t = { id; dev; active; mac } in
  return t

(* Input a frame, and block if nothing is available *)
let rec input t =
  let sz = 4096 in
  let page = Istring.Raw.alloc () in
  let len = Tap.read t.dev page sz in
  match len with
  |(-1) -> (* EAGAIN or EWOULDBLOCK *)
    Activations.read t.dev >>
    input t
  |0 -> (* EOF *)
    t.active <- false;
    Activations.read t.dev >>
    input t
  |n ->
    return (Istring.t page n)

(* Loop and listen for packets permanently *)
let rec listen t fn =
  match t.active with
  |true ->
    lwt frame = input t in
    Lwt.ignore_result (
      try_lwt 
        fn frame
      with exn ->
        return (printf "EXN: %s\n%!" (Printexc.to_string exn))
    );
    listen t fn
  |false ->
    return ()

(* Shutdown a netfront *)
let destroy nf =
  printf "tap_destroy\n%!";
  return ()

(* Transmit a packet from an istring suspension.
   For now, just assume the Tap write wont block for long as this
   is not a performance-critical backend
*)
let output t fn =
  let page = Istring.Raw.alloc () in
  let v = Istring.t page 0 in
  let p = fn v in
  Tap.write t.dev page (Istring.length v);
  return p

(** Return a list of valid VIF IDs *)
let enumerate () =
  return [ "tap0" ]

let mac t =
  t.mac

let string_of_id id = id

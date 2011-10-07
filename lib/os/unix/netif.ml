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

type id = string

type t = {
  id: id;
  dev: [`tap] Socket.fd;
  mutable active: bool;
  mac: string;
}

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

let devices = Hashtbl.create 1

let plug id =
  let dev = Socket.opentap id in
  let mac = generate_local_mac () in
  let active = true in
  let t = { id; dev; active; mac } in
  Hashtbl.add devices id t;
  printf "Netif: plug %s\n%!" id;
  return t

let unplug id =
  try
    let t = Hashtbl.find devices id in
    t.active <- false;
    printf "Netif: unplug %s\n%!" id;
    Hashtbl.remove devices id
  with Not_found -> ()
   
let create fn =
  lwt t = plug "tap0" in (* Just hardcode a tap device for the moment *)
  let user = fn "tap0" t in
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun _ -> unplug "tap0");
  th <?> user

(* Input a frame, and block if nothing is available *)
let rec input t =
  let sz = 4096 in
  let page = String.create sz in
  lwt len = Socket.fdbind Activations.read (fun fd -> Socket.read fd page 0 sz) t.dev in
  match len with
  |(-1) -> (* EAGAIN or EWOULDBLOCK *)
    input t
  |0 -> (* EOF *)
    t.active <- false;
    input t
  |n ->
    return (page, 0, n lsl 3)

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

(* Transmit a packet from a bitstring *)
let output t bss =
  let buf,off,len = Bitstring.concat bss in
  let off = off/8 in
  let len = len/8 in
  lwt len' = Socket.fdbind Activations.write (fun fd -> Socket.write fd buf off len) t.dev in
  if len' <> len then
    raise_lwt (Failure (sprintf "tap: partial write (%d, expected %d)" len' len))
  else
    return ()

let mac t =
  t.mac


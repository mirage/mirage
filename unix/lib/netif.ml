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
  dev: Lwt_unix.file_descr;
  mutable active: bool;
  mac: string;
}

external tap_opendev: string -> Unix.file_descr = "tap_opendev"

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
  let tapfd = tap_opendev id in
  let dev = Lwt_unix.of_unix_file_descr ~blocking:false tapfd in
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

let tapnum = ref 0 
   
let create fn =
  let name = Printf.sprintf "tap%d" !tapnum in
  incr tapnum;
  lwt t = plug name in
  let user = fn name t in
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun _ -> unplug name);
  th <?> user

(* Input a frame, and block if nothing is available *)
let rec input t =
  let page = Io_page.get () in
  let sz = 4096 in
  lwt len = Lwt_bytes.read t.dev page 0 sz in
  match len with
  |(-1) -> (* EAGAIN or EWOULDBLOCK *)
    input t
  |0 -> (* EOF *)
    t.active <- false;
    input t
  |n ->
    return (Cstruct.sub page 0 len)

(* Get write buffer for Netif output *)
let get_writebuf t =
  let page = Io_page.get () in
  (* TODO: record statistics for requesting thread here (in debug mode?) *)
  return page

(* Loop and listen for packets permanently *)
let rec listen t fn =
  match t.active with
  |true ->
    lwt frame = input t in
    Lwt.ignore_result (
      try_lwt 
        fn frame
      with exn ->
        return (printf "EXN: %s bt: %s\n%!" (Printexc.to_string exn) (Printexc.get_backtrace()))
    );
    listen t fn
  |false ->
    return ()

(* Shutdown a netfront *)
let destroy nf =
  printf "tap_destroy\n%!";
  return ()

(* Transmit a packet from an Io_page *)
let write t page =
  let off = Cstruct.base_offset page in
  let len = Cstruct.len page in
  lwt len' = Lwt_bytes.write t.dev page off len in
  if len' <> len then
    raise_lwt (Failure (sprintf "tap: partial write (%d, expected %d)" len' len))
  else
    return ()


(* TODO use writev: but do a copy for now *)
let writev t pages =
  match pages with
  |[] -> return ()
  |[page] -> write t page
  |pages ->
    let page = Io_page.get () in
    let off = ref 0 in
    List.iter (fun p ->
      let len = Cstruct.len p in
      Cstruct.blit_buffer p 0 page !off len;
      off := !off + len;
    ) pages;
    let v = Cstruct.sub page 0 !off in
    write t v
  
let ethid t = 
  t.id

let mac t =
  t.mac 


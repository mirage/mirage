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

open Lwt
open Printf

exception Error of string

type id = string

type t = {
  id: id;
  fd: [`rw_file] Socket.fd;
}

let devices = Hashtbl.create 1

let plug id =
  lwt fd = Socket.(iobind file_open_readwrite id) in
  let t = {id; fd} in
  Hashtbl.add devices id t;
  printf "Blkif: plug %s\n%!" id;
  return t

let unplug id =
  try
    let t = Hashtbl.find devices id in
    printf "Blkif: unplug %s\n%!" id;
    Socket.close t.fd;
    Hashtbl.remove devices id
  with Not_found -> ()

let create fn =
  let default = "disk0.img" in
  lwt t = plug default in (* Just hardcode disk0.img as the sole device for now *)
  let user = fn default t in
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun _ -> unplug default);
  th <?> user

let destroy nf =
  (* XXX TODO unplug devices *)
  printf "Blkif.destroy\n%!";
  return ()

let read_page t offset =
  Socket.(iobind (lseek t.fd) offset) >>
  let buf = String.create 4096 in (* XXX pool? *)
  lwt rd = Socket.(iobind (read t.fd buf 0) 4096) in
  if rd <> 4096 then
    fail (Error "short read") 
  else
    return (buf,0,4096*8)

let sector_size t = 4096

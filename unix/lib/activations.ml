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

exception Cancelled

module FD = struct
  type t = int

  let read_fds = ref []
  let write_fds = ref []
  let exn_fds = ref []

  let read_u : (int,unit Lwt.u) Hashtbl.t = Hashtbl.create 1
  let write_u = Hashtbl.create 1

  external select : t list -> t list -> t list -> float -> t list * t list * t list = "unix_select"

  let add_fd l fd =
    if not (List.mem fd !l) then
      l := fd :: !l

  let remove_fd l fd =
    l := List.filter (fun fd' -> fd <> fd') !l

  let wait timeout =
     (* let fds x = String.concat "," (List.map string_of_int x) in
     Printf.printf "wait %f [%s] [%s] [%s] = " timeout
      (fds !read_fds) (fds !write_fds) (fds !exn_fds); *)
    let rfds,wfds,efds = select !read_fds !write_fds !exn_fds timeout in
    (* Printf.printf " [%s] [%s] [%s]\n" (fds rfds) (fds wfds) (fds efds); *)
    let wakeup_fd h l fn fd =
      try
        let u = Hashtbl.find h fd in
        Hashtbl.remove h fd;
        remove_fd l fd;
        remove_fd exn_fds fd;
        fn u
      with Not_found -> assert false
    in
    List.iter (wakeup_fd read_u read_fds (fun u -> Lwt.wakeup_later u ())) rfds;
    List.iter (wakeup_fd write_u write_fds (fun u -> Lwt.wakeup_later u ())) wfds;
    List.iter (fun efd ->
      if Hashtbl.mem read_u efd then
        wakeup_fd read_u read_fds (fun u -> Lwt.wakeup_later_exn u Cancelled) efd;
      if Hashtbl.mem write_u efd then
        wakeup_fd write_u write_fds (fun u -> Lwt.wakeup_later_exn u Cancelled) efd
    ) efds       

  let read fd = 
    let th,u = Lwt.task () in
    Hashtbl.add read_u fd u;
    add_fd read_fds fd;
    add_fd exn_fds fd;
    th

  let write fd =
    let th,u = Lwt.task () in
    Hashtbl.add write_u fd u;
    add_fd write_fds fd;
    add_fd exn_fds fd;
    th
end

let read fd = FD.read (Socket.fd_to_int fd)
let write fd = FD.write (Socket.fd_to_int fd)
let wait timeout = FD.wait timeout

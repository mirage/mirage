(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

(* TCP channel that uses the UNIX runtime to retrieve fds *)

open Nettypes
open Lwt
open OS

type t = {
  fd: int;
  abort_t: unit Lwt.t;  (* abort thread *)
  abort_u: unit Lwt.u;  (* wakener for socket close *)
}

exception Not_implemented of string
exception Listen_error of string
exception Accept_error of string
exception Connect_error of string
exception Read_error of string
exception Write_error of string

external unix_close: int -> unit = "caml_socket_close"
external unix_tcp_connect: int32 -> int -> int resp = "caml_tcp_connect"
external unix_socket_read: int -> Istring.Raw.t -> int -> int -> int resp = "caml_socket_read"
external unix_socket_write: int -> Istring.Raw.t -> int -> int -> int resp = "caml_socket_write"
external unix_tcp_connect_result: int -> unit resp = "caml_tcp_connect_result"
external unix_tcp_listen: int32 -> int -> int resp = "caml_tcp_listen"
external unix_tcp_accept: int -> (int * int32 * int) resp = "caml_tcp_accept"

let t_of_fd fd =
  let abort_t,abort_u = Lwt.task () in
  { fd; abort_u; abort_t }

let close t =
  unix_close t.fd;
  Lwt.wakeup t.abort_u ();
  return ()

let close_on_exit t fn =
  try_lwt 
    lwt x = fn t in
    close t >>
    return x
  with exn -> 
    close t >>
    fail exn

let connect = function
  |TCP (addr, port) -> begin
    match unix_tcp_connect (ipv4_addr_to_uint32 addr) port with
    |OK fd ->
      (* Wait for the connect to complete *)
      let t = t_of_fd fd in
      let rec loop () =
        Activations.write t.fd >>
        match unix_tcp_connect_result t.fd with
        |OK _ -> return t
        |Err s -> fail (Connect_error s)
        |Retry -> loop () in
      let cancel_t = t.abort_t >> fail (Connect_error "cancelled") in
      loop () <?> cancel_t
    |Err s -> failwith s
    |Retry -> assert false (* initial connect cannot request a retry *)
  end
  |UDP _ -> fail (Not_implemented "UDP")

let with_connection sockaddr fn =
  lwt t = connect sockaddr in
  close_on_exit t fn

let id = new_key ()
let new_id () = Some (Oo.id (object end))
let () =
  Log.set_id (fun () ->
    match get id with
      | None    -> 0
      | Some id -> id)

let listen fn = function
  |TCP (addr, port) -> begin
    Printf.printf "listen: TCP port %d\n%!" port;
    match unix_tcp_listen (ipv4_addr_to_uint32 addr) port with
    |OK fd ->
      let rec loop t =
        with_value id (new_id ()) (fun () ->
          Activations.read t.fd >>
          (match unix_tcp_accept fd with
           |OK (afd,caddr_i,cport) ->
             let caddr = ipv4_addr_of_uint32 caddr_i in
             let csa = TCP (caddr, cport) in
             let t' = t_of_fd afd in
             close_on_exit t' (fn csa) <&> (loop t)
           |Retry -> loop t
           |Err err -> fail (Accept_error err))
         ) in
      let t = t_of_fd fd in
      let listen_t = close_on_exit t loop in
      t.abort_t <?> listen_t
    |Err s ->
       fail (Listen_error s)
    |Retry ->
       fail (Listen_error "listen retry") (* Listen never blocks *)
  end
  | UDP _ -> fail (Not_implemented "UDP")

(* Read a buffer off the wire *)
let rec read_buf t istr off len =
  match unix_socket_read t.fd istr off len with
  |Retry ->
    Activations.read t.fd >>
    read_buf t istr off len
  |OK r -> return r
  |Err e -> fail (Read_error e)

let rec write_buf t istr off len =
  match unix_socket_write t.fd istr off len with 
  |Retry ->
    Activations.write t.fd >>
    write_buf t istr off len
  |OK amt ->
    if amt = len then return ()
    else write_buf t istr (off+amt) (len-amt)
  |Err e -> fail (Write_error e)

let read t =
  let istr = OS.Istring.Raw.alloc () in
  lwt len = read_buf t istr 0 4096 in
  return (Some (OS.Istring.View.t ~off:0 istr len))
  
let write t view =
  let istr = OS.Istring.View.raw view in
  let off = OS.Istring.View.off view in
  let len = OS.Istring.View.length view in
  write_buf t istr off len

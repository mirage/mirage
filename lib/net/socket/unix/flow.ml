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

(* TCP channel that uses the UNIX runtime to retrieve fds *)

open Nettypes
open Lwt
open OS

type t = {
  fd: int;
  mutable active: bool;
  rx_cond: unit Lwt_condition.t;
  tx_cond: unit Lwt_condition.t;
}

exception Not_implemented of string
exception Listen_error of string
exception Accept_error of string
exception Connect_error of string

external unix_close: int -> unit = "caml_socket_close"
external unix_tcp_connect: int32 -> int -> int resp = "caml_tcp_connect"
external unix_socket_read: int -> string -> int -> int -> int resp = "caml_socket_read"
external unix_socket_write: int -> string -> int -> int -> int resp = "caml_socket_write"
external unix_tcp_connect_result: int -> unit resp = "caml_tcp_connect_result"
external unix_tcp_listen: int32 -> int -> int resp = "caml_tcp_listen"
external unix_tcp_accept: int -> (int * int32 * int) resp = "caml_tcp_accept"

let t_of_fd fd = 
  let rx_cond = Lwt_condition.create () in
  let tx_cond = Lwt_condition.create () in
  let active = true in
  { fd; rx_cond; tx_cond; active }

let t_wait_read t  =
  Activations.register_read t.fd (fun _ ->
    Lwt_condition.signal t.rx_cond (); t.active);
  Lwt_condition.wait t.rx_cond

let t_wait_write t =
  Activations.register_write t.fd (fun _ ->
    Lwt_condition.signal t.tx_cond (); t.active);
  Lwt_condition.wait t.tx_cond

let close t = unix_close t.fd

let close_on_exit t fn =
  try_lwt 
    lwt x = fn t in
    close t;
    return x
  with exn -> 
    close t;
    fail exn

let connect = function
  | TCP (addr, port) -> begin
    match unix_tcp_connect (ipv4_addr_to_uint32 addr) port with
    | OK fd ->
      (* Wait for the connect to complete *)
      let t = t_of_fd fd in
      let rec loop () =
        t_wait_write t >>
        match unix_tcp_connect_result t.fd with
        | OK () -> return t
        | Err s -> fail (Connect_error s)
        | Retry -> loop () in
      loop ()
    | Err s -> failwith s
    | Retry -> assert false (* initial connect cannot request a retry *)
  end
  | UDP _ -> fail (Not_implemented "UDP")

let with_connection sockaddr fn =
  lwt t = connect sockaddr in
  close_on_exit t fn

let listen fn = function
  | TCP (addr, port) -> begin
    Printf.printf "listen: TCP port %d\n%!" port;
    match unix_tcp_listen (ipv4_addr_to_uint32 addr) port with
    | OK fd ->
      let lt = t_of_fd fd in
      (* Listen in a loop for new connections *)
      let abort_waiter, abort_wakener = Lwt.task () in
      let rec loop () =
        t_wait_read lt >>
        (match unix_tcp_accept fd with
        | OK (afd,caddr_i,cport) ->
            let caddr = ipv4_addr_of_uint32 caddr_i in
            let csa = TCP (caddr, cport) in
            let t = t_of_fd afd in
            join [ loop (); close_on_exit t (fn csa) ]
        | Retry -> 
            loop () 
        | Err err ->
            Lwt.wakeup_exn abort_wakener (Accept_error err);
            loop ())
      in
      let x = loop () in
      Lwt.on_cancel x (fun () -> close lt);
      Lwt.pick [ abort_waiter; x]
    | Err s ->
       fail (Listen_error s)
    | Retry ->
       assert false (* Listen never blocks *)
  end
  | UDP _ -> fail (Not_implemented "UDP")

let rec read t buf off len =
  match unix_socket_read t.fd buf off len with
  | Retry ->
    (* Would block, so register an activation and wait *)
    t_wait_read t >>
    read t buf off len
  | OK r ->
    return r
  | Err e -> 
    (* Return anything else normally *)
    failwith e

let rec really_read t buf off len =
  read t buf off len >>= function
    | 0 -> fail End_of_file
    | n ->
      let len = len - n in
      if len=0 then
        return ()
      else
        really_read t buf (off+n) len

let rec write t buf off len =
  match unix_socket_write t.fd buf off len with 
  | Retry ->
    (* Would block, so register an activation and wait *)
    t_wait_write t >>
    write t buf off len
  | OK r ->
    return r 
  | Err e ->
    failwith e

let rec really_write t buf off len =
  write t buf off len >>= function
    | 0 -> return ()
    | n -> really_write t buf (off+n) (len-n)

let write_all oc buf =
  let n = String.length buf in
  let rec aux k =
    if k = n then
      return ()
    else begin
      lwt i = write oc buf k (n-k) in aux (k+i)
    end in
  aux 0

(* XXX: very slow *)
let read_char ic =
  let buf = String.create 1 in
  really_read ic buf 0 1 >>
  return buf.[0]

let read_line ic =
  let buf = Buffer.create 128 in
  let rec loop cr_read =
    try_lwt
      read_char ic >>= function
      | '\n' ->
        return(Buffer.contents buf)
      | '\r' ->
        if cr_read then Buffer.add_char buf '\r';
        loop true
      | ch ->
        if cr_read then Buffer.add_char buf '\r';
        Buffer.add_char buf ch;
        loop false
     with
     | End_of_file ->
       if cr_read then Buffer.add_char buf '\r';
       return (Buffer.contents buf)
     | exn ->
       fail exn
  in
  read_char ic >>= function
    | '\r' -> loop true
    | '\n' -> return ""
    | ch -> Buffer.add_char buf ch; loop false

let buffer_size = 4096

let rec read_all ic =
  let buf = Buffer.create buffer_size in
  let str = String.create buffer_size in
  let rec aux () =
    read ic str 0 buffer_size >>= function
    | 0 -> return (Buffer.contents buf)
    | n ->
      Buffer.add_substring buf str 0 n;
      aux () in
  aux ()

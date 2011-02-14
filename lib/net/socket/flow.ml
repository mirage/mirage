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

(* Internal use only *)
type 'a resp =
  |OK of 'a
  |Err of string
  |Retry

type fdwrap = {
  fd: int;
  abort_t: unit Lwt.t;  (* abort thread *)
  abort_u: unit Lwt.u;  (* wakener for socket close *)
}

type ipv4_src = ipv4_addr option * int
type ipv4_dst = ipv4_addr * int

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
(* recvfrom return = from_ip * from_port * length *)
external unix_recvfrom_ipv4: int -> Istring.Raw.t -> int -> int -> (int32 * int * int) resp = "caml_socket_recvfrom_ipv4"
external unix_sendto_ipv4: int -> Istring.Raw.t -> int -> int -> (int32 * int) -> int resp = "caml_socket_sendto_ipv4"
external unix_bind_ipv4: (int32 * int) -> int resp = "caml_udp_bind_ipv4"

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

let connect_tcpv4 (addr,port) fn =
  match unix_tcp_connect (ipv4_addr_to_uint32 addr) port with
  |OK fd ->
    (* Wait for the connect to complete *)
    let t = t_of_fd fd in
    let rec loop () =
      Activations.write t.fd >>
      match unix_tcp_connect_result t.fd with
      |OK _ ->
        close_on_exit t fn
      |Err s -> fail (Connect_error s)
      |Retry -> loop () in
    let cancel_t = t.abort_t >> fail (Connect_error "cancelled") in
    loop () <?> cancel_t
  |Err s -> failwith s
  |Retry -> assert false (* initial connect cannot request a retry *)

let id = new_key ()
let new_id () = Some (Oo.id (object end))
let () =
  Log.set_id (fun () ->
    match get id with
      | None    -> 0
      | Some id -> id)

let listen_tcpv4 addr port fn =
  match unix_tcp_listen (ipv4_addr_to_uint32 addr) port with
  |OK fd ->
    let rec loop t =
      with_value id (new_id ()) (fun () ->
        Activations.read t.fd >>
        (match unix_tcp_accept fd with
         |OK (afd,caddr_i,cport) ->
           let caddr = ipv4_addr_of_uint32 caddr_i in
           let t' = t_of_fd afd in
           let conn_t = close_on_exit t' (fn (caddr, cport)) in
           loop t <&> conn_t
         |Retry -> loop t
         |Err err -> fail (Accept_error err)
        )
      ) in
    let t = t_of_fd fd in
    let listen_t = close_on_exit t loop in
    t.abort_t <?> listen_t
  |Err s ->
    fail (Listen_error s)
  |Retry ->
    fail (Listen_error "listen retry") (* Listen never blocks *)

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
  match len with
  |0 -> return None
  |len -> return (Some (OS.Istring.View.t ~off:0 istr len))
  
let write t view =
  let istr = OS.Istring.View.raw view in
  let off = OS.Istring.View.off view in
  let len = OS.Istring.View.length view in
  write_buf t istr off len

module TCPv4 = struct
  type t = fdwrap
  type mgr = Manager.t
  type src = ipv4_addr option * int
  type dst = ipv4_addr * int

  (* TODO put an istring pool in the manager? *)

  let read = read
  let write = write
  let close = close

  let listen mgr src fn =
    let addr, port = match src with
      |None, port -> ipv4_blank, port
      |Some addr, port -> addr, port in
    listen_tcpv4 addr port fn

  let connect mgr src dst fn =
    connect_tcpv4 dst fn
end

module UDPv4 = struct
  type mgr = Manager.t
  type src = ipv4_addr option * int
  type dst = ipv4_addr * int

  type msg = OS.Istring.View.t

  let rec send mgr ?src (dstaddr, dstport) req =
    lwt fd = match src with
      |None -> return (Manager.get_udpv4 mgr)
      |Some src -> Manager.get_udpv4_listener mgr src
    in
    Activations.write fd >>
    let raw = OS.Istring.View.raw req in
    let off = OS.Istring.View.off req in
    let len = OS.Istring.View.length req in
    let dst = (ipv4_addr_to_uint32 dstaddr, dstport) in
    match unix_sendto_ipv4 fd raw off len dst with
    |OK len' ->
      if len' != len then
        fail (Write_error "partial UDP send")
      else
        return ()
    |Retry -> send mgr (dstaddr, dstport) req
    |Err err -> fail (Write_error err)

  let recv mgr (addr,port) fn =
    lwt lfd = Manager.get_udpv4_listener mgr (addr,port) in
    let rec listen lfd =
      lwt () = Activations.read lfd in
      let istr = OS.Istring.Raw.alloc () in
      match unix_recvfrom_ipv4 lfd istr 0 4096 with
      |OK (frm_addr, frm_port, len) ->
        let frm_addr = ipv4_addr_of_uint32 frm_addr in
        let dst = (frm_addr, frm_port) in
        let req = OS.Istring.View.t ~off:0 istr len in
        let resp_t = fn dst req in
        listen lfd <&> resp_t
      |Retry -> listen lfd
      |Err _ -> return ()
    in 
    listen lfd
    
end

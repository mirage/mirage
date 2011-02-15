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

type ipv4_src = ipv4_addr option * int
type ipv4_dst = ipv4_addr * int

exception Listen_error of string
exception Accept_error of string
exception Connect_error of string
exception Read_error of string
exception Write_error of string

module R = Manager.Unix

type 'a fdwrap = {
  fd: 'a R.fd;
  abort_t: unit Lwt.t;  (* abort thread *)
  abort_u: unit Lwt.u;  (* wakener for socket close *)
}

let t_of_fd fd =
  let abort_t,abort_u = Lwt.task () in
  { fd; abort_u; abort_t }

let close t =
  R.close t.fd;
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

let id = new_key ()
let new_id () = Some (Oo.id (object end))
let () =
  Log.set_id (fun () ->
    match get id with
      | None    -> 0
      | Some id -> id)

let listen_tcpv4 addr port fn =
  lwt fd = match R.tcpv4_bind (ipv4_addr_to_uint32 addr) port with
    |R.OK fd -> return fd
    |R.Err err -> fail (Listen_error err)
    |R.Retry _ -> assert false in
  match R.tcpv4_listen fd with
  |R.OK () ->
    let rec loop t =
      with_value id (new_id ()) (fun () ->
        Activations.read (R.fd t.fd) >>
        (match R.tcpv4_accept fd with
         |R.OK (afd,caddr_i,cport) ->
           let caddr = ipv4_addr_of_uint32 caddr_i in
           let t' = t_of_fd afd in
           let conn_t = close_on_exit t' (fn (caddr, cport)) in
           loop t <&> conn_t
         |R.Retry -> loop t
         |R.Err err -> fail (Accept_error err)
        )
      ) in
    let t = t_of_fd fd in
    let listen_t = close_on_exit t loop in
    t.abort_t <?> listen_t
  |R.Err s ->
    fail (Listen_error s)
  |R.Retry ->
    fail (Listen_error "listen retry") (* Listen never blocks *)

(* Read a buffer off the wire *)
let rec read_buf t istr off len =
  match R.read t.fd istr off len with
  |R.Retry ->
    Activations.read (R.fd t.fd) >>
    read_buf t istr off len
  |R.OK r -> return r
  |R.Err e -> fail (Read_error e)

let rec write_buf t istr off len =
  match R.write t.fd istr off len with 
  |R.Retry ->
    Activations.write (R.fd t.fd) >>
    write_buf t istr off len
  |R.OK amt ->
    if amt = len then return ()
    else write_buf t istr (off+amt) (len-amt)
  |R.Err e -> fail (Write_error e)

let read t =
  let istr = OS.Istring.Raw.alloc () in
  lwt len = read_buf t istr 0 4096 in
  match len with
  |0 -> return None
  |len -> return (Some (OS.Istring.View.t ~off:0 istr len))
  
module TCPv4 = struct
  type t = [`tcpv4] fdwrap
  type mgr = Manager.t
  type src = ipv4_addr option * int
  type dst = ipv4_addr * int

  (* TODO put an istring pool in the manager? *)

  let read = read
  let close = close

  let write t view =
    let istr = OS.Istring.View.raw view in
    let off = OS.Istring.View.off view in
    let len = OS.Istring.View.length view in
    write_buf t istr off len

  let listen mgr src fn =
    let addr, port = match src with
      |None, port -> ipv4_blank, port
      |Some addr, port -> addr, port in
    listen_tcpv4 addr port fn

  let connect mgr ?src (addr,port) fn =
    match R.tcpv4_connect (ipv4_addr_to_uint32 addr) port with
    |R.OK fd ->
      (* Wait for the connect to complete *)
      let t = t_of_fd fd in
      let rec loop () =
        Activations.write (R.fd t.fd) >>
        match R.connect_result t.fd with
        |R.OK _ ->
          close_on_exit t fn
        |R.Err s -> fail (Connect_error s)
        |R.Retry -> loop () in
      let cancel_t = t.abort_t >> fail (Connect_error "cancelled") in
      loop () <?> cancel_t
    |R.Err s -> failwith s
    |R.Retry -> assert false (* initial connect cannot request a retry *)
end

module Pipe = struct
  type t = [`pipe] fdwrap
  type mgr = Manager.t
  type src = int32
  type dst = int32

  type msg = OS.Istring.View.t

  let read t = fail (Failure "read")
  let write t view = fail (Failure "write")
  let close t = fail (Failure "close")
  let connect mgr ?src dstid fn = fail (Failure "connect")
  let listen mgr src fn = fail (Failure "listen")
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
    Activations.write (R.fd fd) >>
    let raw = OS.Istring.View.raw req in
    let off = OS.Istring.View.off req in
    let len = OS.Istring.View.length req in
    let dst = (ipv4_addr_to_uint32 dstaddr, dstport) in
    match R.udpv4_sendto fd raw off len dst with
    |R.OK len' ->
      if len' != len then
        fail (Write_error "partial UDP send")
      else
        return ()
    |R.Retry -> send mgr (dstaddr, dstport) req
    |R.Err err -> fail (Write_error err)

  let recv mgr (addr,port) fn =
    lwt lfd = Manager.get_udpv4_listener mgr (addr,port) in
    let rec listen lfd =
      lwt () = Activations.read (R.fd lfd) in
      let istr = OS.Istring.Raw.alloc () in
      match R.udpv4_recvfrom lfd istr 0 4096 with
      |R.OK (frm_addr, frm_port, len) ->
        let frm_addr = ipv4_addr_of_uint32 frm_addr in
        let dst = (frm_addr, frm_port) in
        let req = OS.Istring.View.t ~off:0 istr len in
        let resp_t = fn dst req in
        listen lfd <&> resp_t
      |R.Retry -> listen lfd
      |R.Err _ -> return ()
    in 
    listen lfd
end

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

(* The manager process binds application ports to interfaces, and
   will eventually deal with load balancing and route determination
   (e.g. if a remote target is on the same host, swap to shared memory *)

open Lwt
open Nettypes
open Printf

exception Error of string

module Unix = struct
  type ipv4 = int32
  type port = int
  type uid = int
  type 'a fd

  type 'a resp =
  | OK of 'a
  | Err of string
  | Retry

  external tcpv4_connect: ipv4 -> port -> [`tcpv4] fd resp = "caml_tcpv4_connect"
  external tcpv4_bind: ipv4 -> port -> [`tcpv4] fd resp = "caml_tcpv4_bind"
  external tcpv4_listen: [`tcpv4] fd -> unit resp = "caml_socket_listen"
  external tcpv4_accept: [`tcpv4] fd -> ([`tcpv4] fd * ipv4 * port) resp = "caml_tcpv4_accept"

  external udpv4_socket: unit -> [`udpv4] fd = "caml_udpv4_socket"
  external udpv4_bind: ipv4 -> port -> [`udpv4] fd resp = "caml_udpv4_bind"
  external udpv4_recvfrom: [`udpv4] fd -> OS.Istring.Raw.t -> int -> int -> (ipv4 * port * int) resp = "caml_udpv4_recvfrom"
  external udpv4_sendto: [`udpv4] fd -> OS.Istring.Raw.t -> int -> int -> (ipv4 * port) -> int resp = "caml_udpv4_sendto"

  external domain_uid: unit -> uid = "caml_domain_name"
  external domain_bind: uid -> [`domain] fd resp = "caml_domain_bind"
  external domain_connect: uid -> [`domain] fd resp = "caml_domain_connect"
  external domain_accept: [`domain] fd -> [`domain] fd resp = "caml_domain_accept"
  external domain_list: unit -> uid list = "caml_domain_list"
  external domain_read: [`domain] fd -> string resp = "caml_domain_read"
  external domain_write: [`domain] fd -> string -> unit resp = "caml_domain_write"
  external domain_send_pipe: [`domain] fd -> [<`rd_pipe|`wr_pipe] fd -> unit resp = "caml_domain_send_fd"
  external domain_recv_pipe: [`domain] fd -> [<`rd_pipe|`wr_pipe] fd resp = "caml_domain_recv_fd"
 
  external pipe: unit -> ([`rd_pipe] fd * [`wr_pipe] fd) resp = "caml_alloc_pipe"

  external connect_result: [<`tcpv4|`domain] fd -> unit resp = "caml_socket_connect_result"

  external read: [<`udpv4|`tcpv4] fd -> OS.Istring.Raw.t -> int -> int -> int resp = "caml_socket_read"
  external write: [<`udpv4|`tcpv4] fd -> OS.Istring.Raw.t -> int -> int -> int resp = "caml_socket_write"
  external close: [<`tcpv4|`udpv4|`domain|`rd_pipe|`wr_pipe] fd -> unit = "caml_socket_close"

  external fd_to_int : 'a fd -> int = "%identity"

  let rec fdbind actfn iofn fd =
    actfn (fd_to_int fd) >>
    match iofn fd with
    |OK x -> return x
    |Err err -> fail (Error err)
    |Retry -> fdbind actfn iofn fd

  let rec iobind iofn arg =
    match iofn arg with
    |OK x -> return x
    |Err err -> fail (Error err)
    |Retry -> assert false
end

open Unix

type t = {
  domain: [`domain] fd;
  udpv4: [`udpv4] fd;
  udpv4_listen_ports: ((ipv4_addr option * int), [`udpv4] fd) Hashtbl.t;
}

let control_t fd =
  let rec accept () =
    lwt lfd = fdbind OS.Activations.read domain_accept fd in
    (* Read the peer uid, uint32_t *)
    lwt uid_s = fdbind OS.Activations.read domain_read lfd in
    let uid = int_of_string uid_s in
    printf "Connection from peer %d\n%!" uid;
    close lfd;
    accept ()
  in accept ()

(* Get a set of all the local peers *)
let local_peers t = domain_list ()

(* Get our local UID *)
let local_uid t = domain_uid ()

(* Ping a peer and see if it is alive *)
let ping_peer t uid =
  let rec connect () =
    try_lwt
      lwt fd = iobind domain_connect uid in
      let our_uid = string_of_int (domain_uid ()) in
      fdbind OS.Activations.write connect_result fd >>
      lwt () = fdbind OS.Activations.write (fun fd -> domain_write fd our_uid) fd in
      close fd;
      printf "Manager.contact_uid: OK -> %d\n%!" uid;
      return true
    with exn ->
      return false
 in connect ()
       
(* Enumerate interfaces and manage the protocol threads *)
let create () =
  let udpv4 = udpv4_socket () in
  let udpv4_listen_ports = Hashtbl.create 7 in
  lwt domain = iobind domain_bind (domain_uid ()) in
  (* TODO: cleanup the domain socket atexit *)
  (* List all other domains at startup *)
  let other_uids = Unix.domain_list () in
  let our_uid = Unix.domain_uid () in
  Printf.printf "Our uid: %d Others: %s\n%!" our_uid
    (String.concat ", " (List.map string_of_int other_uids));
  Gc.compact (); (* XXX debug *)
  let t = { udpv4; udpv4_listen_ports; domain } in
  let th = control_t domain in
  return (t, th)

let get_udpv4 t =
  t.udpv4

(* TODO: sort out cleanup of fds *)
let register_udpv4_listener mgr src fd =
  Hashtbl.add mgr.udpv4_listen_ports src fd

let get_udpv4_listener mgr (addr,port) =
  try
    return (Hashtbl.find mgr.udpv4_listen_ports (addr,port))
  with Not_found -> begin
    let iaddr = match addr with None -> 0l |Some a -> ipv4_addr_to_uint32 a in
    lwt fd = iobind (udpv4_bind iaddr) port in
    register_udpv4_listener mgr (addr,port) fd;
    return fd
  end

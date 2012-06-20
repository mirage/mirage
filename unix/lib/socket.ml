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

(* Access to UNIX sockets *)

open Lwt

exception Error of string

type ipv4 = int32
type port = int
type uid = int
type 'a fd = int

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
external udpv4_recvfrom: [`udpv4] fd -> Io_page.t -> int -> int -> (ipv4 * port * int) resp = "caml_udpv4_recvfrom"
external udpv4_sendto: [`udpv4] fd -> Io_page.t -> int -> int -> (ipv4 * port) -> int resp = "caml_udpv4_sendto"

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

external file_open_readonly: string -> [`ro_file] fd resp = "caml_file_open_ro"
external file_open_readwrite: string -> [`rw_file] fd resp = "caml_file_open_rw"
external lseek: [< `ro_file | `rw_file ] fd -> int64 -> unit resp = "caml_lseek"
external file_size: string -> int64 resp = "caml_stat_size"

type dir
external opendir: string -> dir resp = "caml_opendir"
external readdir: dir -> string resp = "caml_readdir"
external closedir: dir -> unit resp = "caml_closedir"

external read: [<`udpv4|`tcpv4|`rd_pipe|`ro_file|`rw_file|`tap] fd -> Io_page.t -> int -> int -> int resp = "caml_socket_read"
external write: [<`udpv4|`tcpv4|`wr_pipe|`tap|`rw_file] fd -> Io_page.t -> int -> int -> int resp = "caml_socket_write"
external close: [<`tcpv4|`udpv4|`domain|`rd_pipe|`wr_pipe|`ro_file|`rw_file|`tap] fd -> unit = "caml_socket_close"

external opentap: string -> [`tap ] fd = "tap_opendev"

external fd_to_int : 'a fd -> int = "%identity"

(** Given an activation function actfn (to know when the FD is ready),
    perform an iofn repeatedly until either error or value is obtained *)
let rec fdbind actfn iofn fd =
  match iofn fd with
  |OK x -> return x
  |Err err -> fail (Error err)
  |Retry -> actfn (fd_to_int fd) >> fdbind actfn iofn fd

(** Same as fdbind, except on functions that do not need an Activation (e.g. disk fds) *)
let rec iobind iofn arg =
  match iofn arg with
  |OK x -> return x
  |Err err -> fail (Error err)
  |Retry -> iobind iofn arg

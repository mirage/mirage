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

open Mlnet.Types
open Lwt

module Channel : Mlnet.Channel = struct

  type t = {
    fd: int;
    rx_cond: unit Lwt_condition.t;
    tx_cond: unit Lwt_condition.t;
  }

  type 'a resp =
    | OK of 'a
    | Err of string

  exception Not_implemented of string

  type sockaddr = 
    | TCP of ipv4_addr * int
    | UDP of ipv4_addr * int

  external unix_close: int -> unit = "unix_socket_close"
  external unix_tcp_connect: int32 -> int -> int resp = "unix_tcp_connect"
  external unix_socket_read: int -> string -> int -> int -> int resp = "unix_socket_read"
  external unix_socket_write: int -> string -> int -> int -> int resp = "unix_socket_write"

  let rec read t buf off len =
    match unix_socket_read t.fd buf off len with
    | OK 0 ->
        (* Would block, so register an activation and wait *)
        Lwt_condition.wait t.rx_cond >>
        read t buf off len
    | OK _ | Err _ as r -> 
        (* Return anything else normally *)
        return r
        
  let rec write t buf off len =
    match unix_socket_write t.fd buf off len with 
    | OK 0 ->
        (* Would block, so register an activation and wait *)
        Lwt_condition.wait t.tx_cond >>
        write t buf off len
    | OK _ | Err _ as r ->
        (* Return anything else normally *)
        return r

  let connect sa =
    match sa with
    |TCP (addr, port) -> begin
      let c = Lwt_condition.create () in
      match unix_tcp_connect (ipv4_addr_to_uint32 addr) port with
      | OK fd ->
          let rx_cond = Lwt_condition.create () in
          let tx_cond = Lwt_condition.create () in
          let t = { fd; rx_cond; tx_cond } in
          Activations.(register_rd t.fd (Event_condition rx_cond));
          Activations.(register_wr t.fd (Event_condition tx_cond));
          Lwt_condition.wait c >>
          return (OK t)
      | Err s -> 
          return (Err s)
    end
    |UDP _ ->
      fail (Not_implemented "UDP")

  let close t =
    Activations.deregister t.fd;
    unix_close t.fd

end

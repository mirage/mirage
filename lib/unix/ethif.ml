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

module Tap = struct
  type t = int
  external opendev: string -> t = "tap_opendev"
  external read: t -> string -> int -> int -> int = "tap_read"
  external has_input: t -> int = "tap_has_input"
  external write: t -> string -> unit = "tap_write"
  external mac: string -> t -> string = "tap_mac"
end

type t = {
    id: string;
    dev: Tap.t;
    env_pool: string Lwt_pool.t;
    rx_cond: unit Lwt_condition.t;
}

type id = string

let create id =
    let dev = Tap.opendev id in
    let env_pool = Lwt_pool.create 5 
      (fun () -> return (String.make 4096 '\000')) in
    let rx_cond = Lwt_condition.create () in
    Activations.register dev (Activations.Event_condition rx_cond);
    return { id; dev; env_pool; rx_cond }

(* Input all available pages from receive ring and return detached page list *)
let input_raw t =
    [ Tap.read t.dev ]

(* Number of unconsumed responses waiting for receive *)
let has_input t =
    Tap.has_input t.dev > 0

let mac t = Tap.mac t.id t.dev

(* Shutdown a netfront *)
let destroy nf =
    printf "tap_destroy\n%!";
    return ()

(* Transmit a packet from buffer, with offset and length *)  
let output_raw t buf =
    Tap.write t.dev buf;
    return ()  

(** Return a list of valid VIF IDs *)
let enumerate () =
    return [ "tap0" ]

(** Transmit an ethernet frame  *)
let output nf frame =
    Lwt_pool.use nf.env_pool (fun buf ->
      let env = Mpl.Mpl_stdlib.new_env buf in
      let _ = Mpl.Ethernet.m frame env in
      let buf = Mpl.Mpl_stdlib.string_of_env env in
      output_raw nf buf
    )

(** Handle one frame *)
let input nf =
    Lwt_pool.use nf.env_pool (fun buf ->
      let fillfn dst off len = Tap.read nf.dev dst off 4096  in
      let env = Mpl.Mpl_stdlib.new_env ~fillfn buf in
      return (Mpl.Ethernet.unmarshal env)
    )

let wait nf = Lwt_condition.wait nf.rx_cond

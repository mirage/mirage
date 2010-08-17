(*
 * Copyright (c) 2005 Anil Madhavapeddy <anil@recoil.org>
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
 *
 *)

open Mpl
module M = Mpl_stdlib

let ones_checksum sum =
    0xffff - ((sum lsr 16) + (sum land 0xffff))

let ip_checksum sz env =
    let sum = ref 0 in
    for i = 1 to sz do
        let x = M.Mpl_uint16.to_int (M.Mpl_uint16.unmarshal env) in
        let y = M.Mpl_uint16.to_int (M.Mpl_uint16.unmarshal env) in
        let y = if i = 3 then 0 else y in (* zero out checksum header *)
        sum := !sum + x + y;
    done;
    ones_checksum !sum

let data_env ob fn =
    let env = ob#data_env in fn env

(* Given a udp packet and ip info, return a checksum *)
let udp_checksum ip_src ip_dest (udp:Mpl_udp.Udp.o)  =
    let sum = ref 0 in
    let addsum x = sum := !sum + x in
    let add32 x = addsum (Int32.to_int (Int32.shift_right x 16));
        addsum (Int32.to_int (Int32.logand x 65535l)) in
    (* pseudo header *)
    add32 ip_src;
    add32 ip_dest;
    add32 (Int32.of_int udp#total_length);
    addsum 17; (* UDP protocol number *)
    addsum udp#data_length;
    addsum udp#source_port;
    addsum udp#dest_port;
    addsum udp#total_length;
    let len = udp#data_length in
    data_env udp (fun env ->
        for i = 1 to len / 2 do
            addsum (M.Mpl_uint16.to_int (M.Mpl_uint16.unmarshal env))
        done;
        if len mod 2 = 1 then
            addsum (M.Mpl_byte.to_int (M.Mpl_byte.unmarshal env) lsl 8);
    );
    let csum = ones_checksum !sum in
    let csum = if csum = 0 then 0xffff else csum in
    Printf.printf "original: %d  , ours: %d \n" udp#checksum csum;
    csum

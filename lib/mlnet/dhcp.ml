(*
 * Copyright (c) 2006 Anil Madhavapeddy <anil@recoil.org>
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
open Mpl_stdlib
open Mpl_dhcp

let parse_options env optionfn =
    let _ (* cookie *) = Mpl_uint32.unmarshal env in
    let cont = ref true in
    let pos = ref (curpos env) in
    while !cont do
        let env' = env_at env !pos (size env) in
        let o = Dhcp_option.unmarshal env' in
        pos := !pos + (curpos env');
        let () = optionfn o in
        match o with
        |`Pad x -> ()
        |`End x -> cont := false
        |_ -> ()
    done

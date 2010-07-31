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

open Printf
open Lwt
open Mpl_ethernet

module MT = Mlnet_types

let recv netif buf =
    let nf = MT.netfront_of_netif netif in
    (* Just a temporary copying fill function until the paging
       interface is in *)
    let envbuf = String.make 4096 '\000' in
    let fillfn targ off len =
       assert(String.length envbuf > (String.length buf));
       assert(off = 0);
       String.blit buf 0 envbuf off (String.length buf);
       String.length buf in

    let env = Mpl_stdlib.new_env ~fillfn envbuf in
    try_lwt
        let ethernet = Ethernet.unmarshal env in
        match ethernet with
        |`ARP o ->
            Ethernet.ARP.prettyprint o;
            Arp.recv netif o;
        |`IPv4 o ->
            Ethernet.IPv4.prettyprint o;
            return ()
        |_ -> return (printf "discarding non-IPv4/ARP ethernet frame")
    with 
        exn -> return (printf "exn: %s\n%!" (Printexc.to_string exn))

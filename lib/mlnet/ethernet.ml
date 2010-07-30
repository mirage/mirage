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

module ARP = struct
    (* TODO: ARP timeout with an Lwt_pqueue *)
    let mac_cache = Hashtbl.create 1

    let dump_cache () = 
        Hashtbl.iter (fun mac ip -> printf "%s -> %s\n%!" (MT.Ethernet.mac_to_string mac) (MT.IPv4.addr_to_string ip)) mac_cache

    let recv nf (arp:Mpl_ethernet.Ethernet.ARP.o) =
        match arp#ptype with
        |`IPv4 -> begin
            match arp#operation with
            |`Request -> ()
            |`Reply ->
                let frm_mac = MT.Ethernet.mac_of_bytes arp#sha in
                let frm_ip = MT.IPv4.addr_of_bytes arp#spa in
                Hashtbl.replace mac_cache frm_mac frm_ip;
                dump_cache()
            |`Unknown i -> ()
        end
        | _ -> ()

end

module Frame = struct
    let recv nf buf =
        (* Just a temporary copying fill function until the paging
           interface is in *)
        let envbuf = String.make 4096 '\000' in
        let fillfn targ off len =
           assert(String.length envbuf > (String.length buf));
           assert(off = 0);
           String.blit buf 0 envbuf off (String.length buf);
           String.length buf in

        let env = Mpl_stdlib.new_env ~fillfn envbuf in
        (try
            let ethernet = Ethernet.unmarshal env in
            match ethernet with
            |`ARP o ->
                Ethernet.ARP.prettyprint o;
                ARP.recv nf o;
            |`IPv4 o ->
                Ethernet.IPv4.prettyprint o
            |_ -> printf "discarding non-IPv4/ARP ethernet frame"
        with exn -> printf "exn: %s\n%!" (Printexc.to_string exn));
        return ()
    end


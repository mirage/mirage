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
open Mpl
open Mpl_ethernet
open Mpl_ipv4
open Mpl_icmp

module MT = Mlnet_types
module PS = Xen.Page_stream

(* Receive a page, queue it up, and wake up the Ethernet thread *)
let recv netif page =
    let _ = PS.append page netif.MT.recv in
    Lwt_condition.signal netif.MT.recv_cond ()

(* A copying fill function for MPL that acts on pages
 * Temporary until the MPL backend is modified to work directly 
 * the page contents *)
let page_fillfn netif envbuf dstbuf dstoff len =
    assert(not (Lwt_sequence.is_empty netif.MT.recv));
    let ext = Lwt_sequence.take_l netif.MT.recv in
    assert(len < ext.PS.len);
    Hw_page.blit ext.PS.page ext.PS.off dstbuf dstoff ext.PS.len;
    ext.PS.len

(* Loops around waiting for work to do *)
let rec recv_thread netif =
    if Lwt_sequence.is_empty netif.MT.recv then begin
        match netif.MT.state with
        |MT.Netif_shutting_down ->
            (* If the interface is shutting down, and our receive pool
               is empty, exit the thread *)
            return ()
        |_ -> 
            Lwt_condition.wait netif.MT.recv_cond >>
            recv_thread netif
    end else begin
        (* We have work to process! *)
        Lwt_pool.use netif.MT.recv_pool
          (fun envbuf -> 
            let fillfn = page_fillfn netif envbuf in
            let env = Mpl_stdlib.new_env ~fillfn envbuf in
            try_lwt
               match Ethernet.unmarshal env with
               |`ARP o ->
                   Ethernet.ARP.prettyprint o;
                   Arp.recv netif o;
               |`IPv4 o -> begin
                   let ipv4 = Ipv4.unmarshal o#data_env in
                    match ipv4#protocol with
                    |`ICMP -> begin
                        let icmp = Icmp.unmarshal ipv4#data_env in
                        Icmp.prettyprint icmp;
                        return ()
                    end
                    |_ -> return ()
                end
                |_ -> return (printf "discarding non-IPv4/ARP frame")
            with exn -> return (printf "exn:%s\n%!" (Printexc.to_string exn))
          ) >>
        recv_thread netif
    end

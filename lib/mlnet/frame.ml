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
open Mpl_udp

module MT = Mlnet_types

(* Receive a page, queue it up, and wake up the Ethernet thread *)
let recv netif page =
    let _ = Xen.Hw_page.push page netif.MT.recv in
    Lwt_condition.signal netif.MT.recv_cond ()

(* A copying fill function for MPL that acts on pages
 * Temporary until the MPL backend is modified to work directly 
 * the page contents *)
let page_fillfn netif envbuf dstbuf dstoff len =
    Xen.Hw_page.(
      let ext = pop netif.MT.recv in
      assert(len < ext.len);
      blit ext.page ext.off dstbuf dstoff ext.len;
      ext.len
    )

(* Loops around waiting for work to do *)
let rec recv_thread netif =
    if Xen.Hw_page.is_empty netif.MT.recv then begin
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
        Lwt_pool.use netif.MT.env_pool
          (fun envbuf -> 
            let fillfn = page_fillfn netif envbuf in
            let env = Mpl_stdlib.new_env ~fillfn envbuf in
            try_lwt
               match Ethernet.unmarshal env with
               |`ARP o ->
                   Arp.recv netif o;
               |`IPv4 o -> begin
                   let ipv4 = Ipv4.unmarshal o#data_env in
                    match ipv4#protocol with
                    |`ICMP ->
                        let icmp = Icmp.unmarshal ipv4#data_env in
                        Icmp.prettyprint icmp;
                        return ()
                    |`UDP -> begin
                        let udp = Udp.unmarshal ipv4#data_env in
                        match udp#source_port, udp#dest_port with
                        |67,68 (* dhcp reply *) -> Dhcp.Client.recv netif udp
                        |68,67 (* dhcp broadcast *) -> (* discard *) return ()
                        |_ -> return (print_endline "unknown udp")
                    end
                    |_ -> 
                        return ()
                end
                |x ->
                  (* Ethernet.prettyprint x; *)
                  return (printf "discarding non-IPv4/ARP frame\n")
            with exn -> return (printf "exn:%s\n%!" (Printexc.to_string exn))
          ) >>
        recv_thread netif
    end

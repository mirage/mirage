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

module IPv4 (IF:Ethif.UP)
            (ARP:Arp.UP with type id=IF.id and type ethif=IF.t) = struct

  type state =
  |Obtaining_ip
  |Up
  |Down
  |Shutting_down

  type t = {
    ethif: IF.t;
    arp: ARP.t;
    thread: unit Lwt.t;
  }

  let create_dhcp id = 
    lwt (ethif, ethif_t) = IF.create id in
    let arp, arp_t = ARP.create ethif in
    let thread,_ = Lwt.task () in
    let t = { ethif; arp; thread } in
    printf "IPv4.create_dhcp done\n%!";
    let dhcp_t = join [ethif_t; arp_t; thread ] in
    return (t, dhcp_t)

end

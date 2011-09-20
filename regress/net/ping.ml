(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
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

let main () = 
  Log.info "Ping" "starting server";
  Net.Manager.create (fun mgr interface id ->
    let ip = Net.Nettypes.(
      (ipv4_addr_of_tuple (10l,0l,0l,2l),
       ipv4_addr_of_tuple (255l,255l,255l,0l),
       [ ipv4_addr_of_tuple (10l,0l,0l,1l) ]
      ))
    in
    Net.Manager.configure interface (`IPv4 ip)
    >> (let icmp_t, th = 
          Net.Icmp.create (Net.Manager.ipv4_of_interface interface)
        in th)
    >> return (OS.Console.log "success!\n")
  )

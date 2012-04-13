(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
 * Derived from code by Anil Madhavapeddy <anil@recoil.org>
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

let port = 55555
let use_dhcp = false

let ip = Net.Nettypes.(
  (ipv4_addr_of_tuple (10l,0l,0l,2l),
   ipv4_addr_of_tuple (255l,255l,255l,0l),
   [ ipv4_addr_of_tuple (10l,0l,0l,1l) ]
  ))

let rec echo (rip,rpt) pcb = 
  let open Net in
  match_lwt Tcp.Pcb.read pcb with
   | None -> Tcp.Pcb.close pcb
   | Some bits -> begin
       let s = Bitstring.string_of_bitstring bits in
       let len = Bitstring.bitstring_length bits in
       Tcp.Pcb.write_wait_for pcb len
       >> Tcp.Pcb.write pcb bits
       >> echo (rip,rpt) pcb
   end

let main () =
  Log.info "Tcp_echo" "starting server";
  Net.(Manager.create (fun mgr interface id ->
    lwt () = (match use_dhcp with
      | false -> Manager.configure interface (`IPv4 ip)
      | true -> Manager.configure interface (`DHCP)
    )
    in
    let ipv4 = Manager.ipv4_of_interface interface in
    let _, icmp_th = Icmp.create ipv4 in
    let tcp, tcp_th = Tcp.Pcb.create ipv4 in
    Tcp.Pcb.listen tcp port echo
    >> (icmp_th <?> tcp_th)
  ))
  >> return (Log.info "Tcp_echo" "success")

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

open Dns.Packet.Questions

let pr = Printf.printf

type t = {
  ip: Net.Ipv4.t;
  udp: Net.Udp.t;
  name: string;
}

type entry = {
  time: float;
  name: string;
  addrs: Net.Nettypes.ipv4_addr list;
}

let name = "google.com"
let names = [ name; "nottingham.ac.uk"; "cl.cam.ac.uk" ]
let google_resolver = Net.Nettypes.ipv4_addr_of_string "8.8.8.8"
  
let resolv t =
  
(*
  let name =
    let raw = OS.Istring.Raw.alloc () in
    let istr = OS.Istring.t ~off:0 raw (String.length t.name) in
    istr
  in
*)

(*
  let labels = Dns.Mpl_dns_label.of_string_list [ t.name ] in
*)
  let qs = List.map (fun label -> { env=(1 * [ "s" ]); qname=label }) labels in
  let dnsfn env = 
    ignore(Dns.Packet.t ~qr:`Query ~opcode:`Query ~questions:qs)
  in
  let udpfn = Mpl.Udp.t ~dest_port:53 ~checksum:0 ~data:(`Sub dnsfn) in
  let dstip = google_resolver in
  
  pr "dns: tx\n";
  Udp.output t.udp ~dstip udpfn

let main () = 
  
  let vifs = OS.Ethif.enumerate () in
  let vif = List.hd vifs in
  let ip, _ = Ipv4.create vif in
  let udp, _ = Udp.create ip in
  
  let t = { ip; udp; name } in
  resolv t
     
let _ = OS.Main.run (main ())

(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

open Lwt
open Nettypes
open Printf

(* TODO implement the full ARP state machine (pending, failed, timer thread, etc) *)
type entry =
  | Incomplete of ethernet_mac Lwt_condition.t
  | Verified of ethernet_mac

type t = {
  output: arp -> unit Lwt.t;
  get_mac: unit -> ethernet_mac;
  cache: (ipv4_addr, entry) Hashtbl.t;
  mutable bound_ips: ipv4_addr list;
 }

(* Prettyprint cache contents *)
let prettyprint t =
  printf "ARP info:\n"; 
  Hashtbl.iter (fun ip entry -> 
    printf "%s -> %s\n%!" 
     (ipv4_addr_to_string ip)
     (match entry with
      | Incomplete _ -> "I"
      | Verified mac -> sprintf "V(%s)" (ethernet_mac_to_string mac)
     )
  ) t.cache

(* Input handler for an ARP packet, registered through attach() *)
let input t arp =
  match arp.op with
  |`Request ->
    (* Received ARP request, check if we can satisfy it from
       our own IPv4 list *)
    let req_ipv4 = arp.tpa in
    printf "ARP: who-has %s?\n%!" (ipv4_addr_to_string req_ipv4);
    if List.mem req_ipv4 t.bound_ips then begin
      (* We own this IP, so reply with our MAC *)
      let sha = t.get_mac () in
      let tha = arp.sha in
      let spa = arp.tpa in (* the requested address *)
      let tpa = arp.spa in (* the requesting host IPv4 *)
      t.output { op=`Reply; sha; tha; spa; tpa }
    end else return ()
  |`Reply ->
    printf "ARP: updating %s -> %s\n%!"
      (ipv4_addr_to_string arp.spa) (ethernet_mac_to_string arp.sha);
    (* If we have pending entry, notify the waiters that answer is ready *)
    if Hashtbl.mem t.cache arp.spa then begin
      match Hashtbl.find t.cache arp.spa with
      |Incomplete cond -> Lwt_condition.broadcast cond arp.sha
      |_ -> ()
    end;
    Hashtbl.replace t.cache arp.spa (Verified arp.sha);
    return ()
  |`Unknown _ -> return ()

(* Send a gratuitous ARP for our IP addresses *)
let output_garp t =
  let tha = ethernet_mac_broadcast in
  let sha = t.get_mac () in
  let tpa = ipv4_blank in
  Lwt_list.iter_s (fun spa ->
    printf "ARP: sending gratuitous from %s\n%!" (ipv4_addr_to_string spa);
    t.output { op=`Reply; tha; sha; tpa; spa }
  ) t.bound_ips

(* Send a query for a particular IP *)
let output_probe t tpa =
  let tha = ethernet_mac_broadcast in
  let sha = t.get_mac () in
  (* Source protocol address, pick one of our IP addresses *)
  let spa = match t.bound_ips with
    | hd::tl -> hd | [] -> ipv4_blank in
  t.output { op=`Reply; tha; sha; tpa; spa }

let get_ips t = t.bound_ips

(* Set the bound IP address list, which will xmit a GARP packet also *)
let set_ips t ips =
  t.bound_ips <- ips;
  output_garp t

let add_ip t ip =
  if not (List.mem ip t.bound_ips) then
    set_ips t (ip :: t.bound_ips)
  else return ()

let remove_ip t ip =
  if List.mem ip t.bound_ips then
    set_ips t (List.filter ((<>) ip) t.bound_ips)
  else return ()

(* Query the cache for an ARP entry, which may result in the sender sleeping
   waiting for a response *)
let query t ip =
  if Hashtbl.mem t.cache ip then (
    match Hashtbl.find t.cache ip with
    | Incomplete cond ->
       printf "ARP query: %s -> [incomplete]\n%!" (ipv4_addr_to_string ip);
       Lwt_condition.wait cond
    | Verified mac ->
       printf "ARP query: %s -> %s\n%!"
         (ipv4_addr_to_string ip) (ethernet_mac_to_string mac);
       return mac
  ) else (
    let cond = Lwt_condition.create () in
    printf "ARP query: %s -> [probe]\n%!" (ipv4_addr_to_string ip);
    Hashtbl.add t.cache ip (Incomplete cond);
    (* First request, so send a query packet *)
    lwt () = output_probe t ip in
    Lwt_condition.wait cond
  )

let create ~output ~get_mac =
  let cache = Hashtbl.create 7 in
  let bound_ips = [] in
  { output; get_mac; cache; bound_ips }

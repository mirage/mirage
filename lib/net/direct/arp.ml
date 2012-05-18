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
  get_etherbuf: unit -> (OS.Io_page.t * int) Lwt.t;
  output: OS.Io_page.t -> unit Lwt.t;
  get_mac: unit -> ethernet_mac;
  cache: (ipv4_addr, entry) Hashtbl.t;
  mutable bound_ips: ipv4_addr list;
 }

cstruct arp {
  uint8_t dst[6];
  uint8_t src[6];
  uint16_t ethertype;
  uint16_t htype;
  uint16_t ptype;
  uint8_t hlen;
  uint8_t plen;
  uint16_t op;
  uint8_t sha[6];
  uint32_t spa;
  uint8_t tha[6];
  uint32_t tpa
} as big_endian

cenum op {
  Op_request = 1;
  Op_reply
} as uint16_t

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
let rec input t frame =
  match op_of_int (get_arp_op frame) with
  |Some Op_request ->
    (* Received ARP request, check if we can satisfy it from
       our own IPv4 list *)
    let req_ipv4 = ipv4_addr_of_uint32 (get_arp_tpa frame) in
    printf "ARP: who-has %s?\n%!" (ipv4_addr_to_string req_ipv4);
    if List.mem req_ipv4 t.bound_ips then begin
      (* We own this IP, so reply with our MAC *)
      let sha = t.get_mac () in
      let tha = ethernet_mac_of_bytes (copy_arp_sha frame) in
      let spa = ipv4_addr_of_uint32 (get_arp_tpa frame) in (* the requested address *)
      let tpa = ipv4_addr_of_uint32 (get_arp_spa frame) in (* the requesting host IPv4 *)
      output t { op=`Reply; sha; tha; spa; tpa }
    end else return ()
  |Some Op_reply ->
    let spa = ipv4_addr_of_uint32 (get_arp_tpa frame) in
    let sha = ethernet_mac_of_bytes (copy_arp_sha frame) in
    printf "ARP: updating %s -> %s\n%!"
      (ipv4_addr_to_string spa) (ethernet_mac_to_string sha);
    (* If we have pending entry, notify the waiters that answer is ready *)
    if Hashtbl.mem t.cache spa then begin
      match Hashtbl.find t.cache spa with
      |Incomplete cond -> Lwt_condition.broadcast cond sha
      |_ -> ()
    end;
    Hashtbl.replace t.cache spa (Verified sha);
    return ()
  |None ->
    printf "ARP: Unknown message ignored\n%!";
    return ()

and output t arp =
  (* Obtain a buffer to write into *)
  lwt buf,_ = t.get_etherbuf () in
  (* Write the ARP packet *)
  let dmac = ethernet_mac_to_bytes arp.tha in
  let smac = ethernet_mac_to_bytes arp.sha in
  let spa = ipv4_addr_to_uint32 arp.spa in
  let tpa = ipv4_addr_to_uint32 arp.tpa in
  let op =
    match arp.op with
    |`Request -> 1
    |`Reply -> 2 
    |`Unknown n -> n 
  in
  set_arp_dst dmac 0 buf;
  set_arp_src smac 0 buf;
  set_arp_ethertype buf 0x0806; (* ARP *)
  set_arp_htype buf 1; 
  set_arp_ptype buf 0x0800; (* IPv4 *)
  set_arp_hlen buf 6; (* ethernet mac size *)
  set_arp_plen buf 4; (* ipv4 size *)
  set_arp_op buf op;
  set_arp_sha smac 0 buf;
  set_arp_spa buf spa;
  set_arp_tha dmac 0 buf;
  set_arp_tpa buf tpa;
  t.output buf

(* Send a gratuitous ARP for our IP addresses *)
let output_garp t =
  let tha = ethernet_mac_broadcast in
  let sha = t.get_mac () in
  let tpa = ipv4_blank in
  Lwt_list.iter_s (fun spa ->
    printf "ARP: sending gratuitous from %s\n%!" (ipv4_addr_to_string spa);
    output t { op=`Reply; tha; sha; tpa; spa }
  ) t.bound_ips

(* Send a query for a particular IP *)
let output_probe t tpa =
  printf "ARP: transmitting probe -> %s\n%!" (ipv4_addr_to_string tpa);
  let tha = ethernet_mac_broadcast in
  let sha = t.get_mac () in
  (* Source protocol address, pick one of our IP addresses *)
  let spa = match t.bound_ips with
    | hd::tl -> hd | [] -> ipv4_blank in
  output t { op=`Request; tha; sha; tpa; spa }

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
       (* printf "ARP query: %s -> [incomplete]\n%!" (ipv4_addr_to_string ip); *)
       Lwt_condition.wait cond
    | Verified mac ->
       (* printf "ARP query: %s -> %s\n%!"
         (ipv4_addr_to_string ip) (ethernet_mac_to_string mac); *)
       return mac
  ) else (
    let cond = Lwt_condition.create () in
    (* printf "ARP query: %s -> [probe]\n%!" (ipv4_addr_to_string ip); *)
    Hashtbl.add t.cache ip (Incomplete cond);
    (* First request, so send a query packet *)
    lwt () = output_probe t ip in
    Lwt_condition.wait cond
  )

let create ~get_etherbuf ~output ~get_mac =
  let cache = Hashtbl.create 7 in
  let bound_ips = [] in
  { output; get_mac; cache; bound_ips; get_etherbuf }

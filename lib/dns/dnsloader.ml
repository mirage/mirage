(*
 * Copyright (c) 2005-2006 Tim Deegan <tjd@phlegethon.org>
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
 * dnsloader.ml -- how to build up a DNS trie from separate RRs
 *
 *)

open Dnsrr
open Dnstrie

(* Loader database: the DNS trie plus a hash table of other names in use *)
type db = {
    trie: dnstrie;		       	     (* Names that have RRSets *)
    mutable names: (key, dnsnode) Hashtbl.t; (* All other names *)
  } 

(* Get a new, empty database *)
let new_db () = { trie = new_trie (); 
		  names = Hashtbl.create 101; 
		} 

(* Throw away the known names: call when guaranteed no more updates *)
let no_more_updates db = Hashtbl.clear db.names; db.names <- Hashtbl.create 1

(* Get the dnsnode that represents this name, making a new one if needed *)
let get_target_dnsnode owner db = 
  let key = canon2key owner in 
  match simple_lookup key db.trie with
    Some n -> n
  | None -> 
      try 
      	Hashtbl.find db.names key
      with Not_found -> 
	let n = { owner = hashcons_domainname owner;
		  rrsets = []; }
	in Hashtbl.add db.names key n ; 
	n

(* Get the dnsnode that represents this name, making a new one if needed,
   inserting it into the trie, and returning both trie node and dnsnode *)
let get_owner_dnsnode owner db = 
  let pull_name tbl key owner () = 
    try
      match Hashtbl.find tbl key with 
	d -> Hashtbl.remove tbl key; d
    with Not_found -> { owner = hashcons_domainname owner;
			rrsets = []; } 
  in
  let key = canon2key owner in
  lookup_or_insert key db.trie (pull_name db.names key owner)


(* How to add each type of RR to the database... *)
exception TTLMismatch

let add_rrset rrset owner db = 
  let ownernode = get_owner_dnsnode owner db in
  let (old_ttl, new_rrsets) = merge_rrset rrset ownernode.rrsets in 
  ownernode.rrsets <- new_rrsets;
  if not (old_ttl = rrset.ttl) then raise TTLMismatch 

let add_generic_rr tcode str ttl owner db =
  let s = hashcons_charstring str in 
  add_rrset { ttl = ttl; rdata = Unknown (tcode, [ s ]) } owner db

let add_a_rr ip ttl owner db =
  add_rrset { ttl = ttl; rdata = A [ ip ] } owner db

let add_ns_rr target ttl owner db =
  try
    let targetnode = get_target_dnsnode target db in
    add_rrset { ttl = ttl; rdata = NS [ targetnode ] } owner db;
    fix_flags (canon2key owner) db.trie  
  with TTLMismatch -> 
    fix_flags (canon2key owner) db.trie; raise TTLMismatch

let add_cname_rr target ttl owner db =
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; rdata = CNAME [ targetnode ] } owner db

let add_soa_rr master rp serial refresh retry expiry min ttl owner db =
  try 
    let masternode = get_target_dnsnode master db in
    let rpnode = get_target_dnsnode rp db in
    let rdata = (masternode, rpnode, serial, refresh, retry, expiry, min) in 
    add_rrset { ttl = ttl; rdata = SOA [ rdata ] } owner db;
    fix_flags (canon2key owner) db.trie
  with TTLMismatch -> 
    fix_flags (canon2key owner) db.trie; raise TTLMismatch

let add_mb_rr target ttl owner db =
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; rdata = MB [ targetnode ] } owner db

let add_mg_rr target ttl owner db =
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; rdata = MG [ targetnode ] } owner db

let add_mr_rr target ttl owner db =
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; rdata = MR [ targetnode ] } owner db

let add_wks_rr addr prot bitmap ttl owner db =
  let b = hashcons_charstring bitmap in 
  add_rrset { ttl = ttl; rdata = WKS [ (addr, prot, b) ] } owner db

let add_ptr_rr target ttl owner db =
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; rdata = PTR [ targetnode ] } owner db

let add_hinfo_rr cpu os ttl owner db =
  let c = hashcons_charstring cpu in 
  let o = hashcons_charstring os in 
  add_rrset { ttl = ttl; rdata = HINFO [ (c, o) ] } owner db

let add_minfo_rr rmailbx emailbx ttl owner db =
  let rtarget = get_target_dnsnode rmailbx db in
  let etarget = get_target_dnsnode emailbx db in
  add_rrset { ttl = ttl; rdata = MINFO [ (rtarget, etarget) ] } owner db

let add_mx_rr pri target ttl owner db =
  let pri = min pri 0xffff in
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; rdata = MX [ (pri, targetnode) ] } owner db

let add_txt_rr strl ttl owner db =
  let sl = List.map hashcons_charstring strl in 
  add_rrset { ttl = ttl; rdata = TXT [ sl ] } owner db

let add_rp_rr mbox txt ttl owner db =
  let mtarget = get_target_dnsnode mbox db in
  let ttarget = get_target_dnsnode txt db in
  add_rrset { ttl = ttl; rdata = RP [ (mtarget, ttarget) ] } owner db

let add_afsdb_rr subtype target ttl owner db =
  let st = min subtype 0xffff in
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; rdata = AFSDB [ (st, targetnode) ] } owner db

let add_x25_rr addr ttl owner db =
  let a = hashcons_charstring addr in 
  add_rrset { ttl = ttl; rdata = X25 [ a ] } owner db

let add_isdn_rr addr sa ttl owner db =
  let a = hashcons_charstring addr in 
  let s = match sa with 
    None -> None 
  | Some x -> Some (hashcons_charstring x) in 
  add_rrset { ttl = ttl; rdata = ISDN [ (a, s) ] } owner db

let add_rt_rr pref target ttl owner db =
  let pref = min pref 0xffff in
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; rdata = RT [ (pref, targetnode) ] } owner db

let add_aaaa_rr str ttl owner db =
  let s = hashcons_charstring str in 
  add_rrset { ttl = ttl; rdata = AAAA [ s ] } owner db

let add_srv_rr pri weight port target ttl owner db = 
  let pri = min pri 0xffff in
  let weight = min weight 0xffff in
  let port = min port 0xffff in
  let targetnode = get_target_dnsnode target db in
  add_rrset { ttl = ttl; 
	      rdata = SRV [ (pri, weight, port, targetnode) ] } owner db

let add_unspec_rr str ttl owner db =
  let s = hashcons_charstring str in 
  add_rrset { ttl = ttl; rdata = UNSPEC [ s ] } owner db
  

(* State variables for the parser & lexer *)
type parserstate = {
    mutable db: db;
    mutable paren: int;
    mutable filename: string;
    mutable lineno: int;
    mutable origin: string list;
    mutable ttl: int32;
    mutable owner: string list;
  }

let state = {
  db = new_db ();
  paren = 0;
  filename = "";
  lineno = 1;
  ttl = Int32.of_int 3600;
  origin = [];
  owner = [];
}

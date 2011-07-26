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
 * dnsquery.ml -- map DNS query-response mechanism onto trie database
 *
 *)

open Dnsrr
open Dnstrie

module DP = Dnspacket
module H = Hashcons

(* We answer a query with RCODE, AA, ANSWERS, AUTHORITY and ADDITIONAL *)

type query_answer = {
  rcode : DP.rcode;
  aa: bool;
  answer: DP.rsrc_record list;
  authority: DP.rsrc_record list;
  additional: DP.rsrc_record list;
} 

let answer_query qname qtype trie = 

  let aa_flag = ref true in
  let ans_rrs = ref [] in
  let auth_rrs = ref [] in
  let add_rrs = ref [] in
  let addqueue = ref [] in
  let rrlog = ref [] in 

  (* We must avoid repeating RRSets in the response.  To do this, we
     keep two lists: one of RRSets that are already included, and one of
     RRSets we plan to put in the additional records section.  When we
     add an RRSet to the answer or authority section we strip it from
     the additionals queue, and when we enqueue an additional RRSet we
     make sure it's not already been included.  
     N.B. (1) We only log those types that might turn up more than once. 
     N.B. (2) We can use "==" and "!=" because owners are unique:
     they are either the owner field of a dnsnode from the 
     trie, or they are the qname, which only happens if it 
     does not have any RRSets of its own and matched a wildcard.*)
  let log_rrset owner rrtype =
    addqueue := List.filter 
	  (fun (n, t) -> rrtype != t || owner != n.owner.H.node) !addqueue;
    rrlog := (owner, rrtype) :: !rrlog
  in
  let in_log owner rrtype = 
    List.exists (fun (o, t) -> o == owner && t == rrtype) !rrlog
  in
  let enqueue_additional dnsnode rrtype = 
    if not (in_log dnsnode.owner.H.node rrtype) 
    then addqueue := (dnsnode, rrtype) :: !addqueue 
  in

  let add_rrset owner ttl rdata section = 
    let addrr ?(rrclass = Some `IN) rr = 
      let rrclass = match rrclass with
        | Some x -> x
        | None   -> failwith "unknown rrclass"
      in
      let rr = DP.({ rr_name = owner; 
                     rr_class = rrclass; 
                     rr_ttl = ttl; 
                     rr_rdata = rr }) 
      in
      match section with 
        | `Answer     -> ans_rrs  := rr :: !ans_rrs 
        | `Authority  -> auth_rrs := rr :: !auth_rrs 
        | `Additional -> add_rrs  := rr :: !add_rrs 
    in
    
    (* having extracted record from trie, partially marshal it *)
    match rdata with 
      | A l -> log_rrset owner `A; 
        List.iter (fun ip -> addrr (`A ip)) l
          
      | NS l -> log_rrset owner `NS;
	    List.iter (fun d -> 
	      enqueue_additional d `A; enqueue_additional d `AAAA;
          addrr (`NS d.owner.H.node)
        ) l 
          
      | CNAME l -> 
	    List.iter (fun d -> 
	      addrr (`CNAME d.owner.H.node)) l
          
      | SOA l -> log_rrset owner `SOA;
	    List.iter (fun (prim,admin,serial,refresh,retry,expiration,minttl) ->
          addrr (`SOA (prim.owner.H.node,
			           admin.owner.H.node, 
                       serial, refresh, retry, expiration, minttl))) l

      | MB l -> 
	    List.iter (fun d -> 
	      enqueue_additional d `A;
	      enqueue_additional d `AAAA;
	      addrr (`MB d.owner.H.node)) l
          
      | MG l -> 
	    List.iter (fun d -> 
	      addrr (`MG d.owner.H.node)) l
          
      | MR l -> 
	    List.iter (fun d -> 
	      addrr (`MR d.owner.H.node)) l
          
      | WKS l -> 
	    List.iter (fun (address, protocol, bitmap) -> 
	      addrr (`WKS (address, DP.byte protocol, bitmap.H.node))) l

      | PTR l -> 
	    List.iter (fun d -> 
	      addrr (`PTR d.owner.H.node)) l
          
      | HINFO l -> 
	    List.iter (fun (cpu, os) -> 
	      addrr (`HINFO (cpu.H.node, os.H.node))) l
          
      | MINFO l -> 
	    List.iter (fun (rm, em) -> 
	      addrr (`MINFO (rm.owner.H.node, em.owner.H.node))) l
          
      | MX l -> 
	    List.iter (fun (preference, d) -> 
	      enqueue_additional d `A;
	      enqueue_additional d `AAAA;
	      addrr (`MX (preference, d.owner.H.node))) l
          
      | TXT l ->
	    List.iter (fun sl -> (* XXX handle multiple TXT cstrings properly *)
	      let data = List.map (fun x -> x.H.node) sl in 
          addrr (`TXT data)) l
          
      | RP l -> 
	    List.iter (fun (mbox, txt) -> 
	      addrr (`RP (mbox.owner.H.node, txt.owner.H.node))) l
          
      | AFSDB l ->
	    List.iter (fun (t, d) -> 
	      enqueue_additional d `A;
	      enqueue_additional d `AAAA;
	      addrr (`AFSDB (t, d.owner.H.node))) l
          
      | X25 l -> log_rrset owner `X25;
	    List.iter (fun s -> 
	      addrr (`X25 s.H.node)) l
          
      | ISDN l -> log_rrset owner `ISDN;
	    List.iter (function (* XXX handle multiple cstrings properly *)
          | (addr, None) 
            -> addrr (`ISDN addr.H.node)
          | (addr, Some sa) (* XXX Handle multiple charstrings properly *)
            -> addrr (`ISDN (addr.H.node ^ sa.H.node))) l
          
      | RT l -> 
	    List.iter (fun (preference, d) -> 
	      enqueue_additional d `A;
	      enqueue_additional d `AAAA;
	      enqueue_additional d `X25;
	      enqueue_additional d `ISDN;
	      addrr (`RT (~preference, d.owner.H.node))) l
          
      | AAAA l -> log_rrset owner `AAAA;
	    List.iter (fun i -> addrr (`AAAA i.H.node)) l 
          
      | SRV l 
        -> List.iter (fun (priority, weight, port, d) -> 
	      enqueue_additional d `A;
	      enqueue_additional d `AAAA;
	      addrr (`SRV (priority, weight, port, d.owner.H.node))) l
        
      | UNSPEC l 
        -> List.iter (fun s -> addrr (`UNSPEC s.H.node)) l

      | Unknown (t,l)
        -> DP.(
          let s = l ||> (fun x -> x.H.node) |> String.concat "" in 
          addrr (`UNKNOWN (t, s))
        )

  in
  
  (* Get an RRSet, which may not exist *)
  let add_opt_rrset node rrtype section = 
    if not (in_log node.owner.H.node rrtype)
    then let a = get_rrsets rrtype node.rrsets false in
         List.iter (fun s -> add_rrset node.owner.H.node s.ttl s.rdata section) a 
  in

  (* Get an RRSet, which must exist *)
  let add_req_rrset node rrtype section = 
    if not (in_log node.owner.H.node rrtype)
    then let a = get_rrsets rrtype node.rrsets false in
         if a = [] then raise TrieCorrupt; 
         List.iter (fun s -> add_rrset node.owner.H.node s.ttl s.rdata section) a
  in

  (* Get the SOA RRSet for a negative response *)
  let add_negative_soa_rrset node = 
    (* Don't need to check if it's already there *)
    let a = get_rrsets `SOA node.rrsets false in
    if a = [] then raise TrieCorrupt;
    (* RFC 2308: The TTL of the SOA RRset in a negative response must be set to
       the minimum of its own TTL and the "minimum" field of the SOA itself *)
    List.iter (fun s -> 
      match s.rdata with
	      SOA ((_, _, _, _, _, _, ttl) :: _) -> 
	        add_rrset node.owner.H.node (min s.ttl ttl) s.rdata `Authority
        | _ -> raise TrieCorrupt ) a
  in

  (* Fill in the ANSWER section *)
  let rec add_answer_rrsets owner ?(lc = 5) rrsets rrtype  = 
    let add_answer_rrset s = 
      match s with 
	      { rdata = CNAME (d::_) } -> (* Only follow the first CNAME in a set *)
	        if not (lc < 1 || rrtype = `CNAME ) then begin 
              add_answer_rrsets d.owner.H.node ~lc:(lc - 1) d.rrsets rrtype end;
	        add_rrset owner s.ttl s.rdata `Answer;
        | _ -> add_rrset owner s.ttl s.rdata `Answer
    in
    let a = get_rrsets rrtype rrsets true in
    List.iter add_answer_rrset a
  in

  (* Call the trie lookup and assemble the RRs for a response *)
  let main_lookup qname qtype trie = 
    let key = canon2key qname in
    match lookup key trie with
        `Found (sec, node, zonehead) ->	  (* Name has RRs, and we own it. *)
	      add_answer_rrsets node.owner.H.node node.rrsets qtype;
	      add_opt_rrset zonehead `NS `Authority;
	      `NoError
	        
      | `NoError (zonehead) ->	 	  (* Name "exists", but has no RRs. *)
	    add_negative_soa_rrset zonehead;
	    `NoError

      | `NoErrorNSEC (zonehead, nsec) ->
	    add_negative_soa_rrset zonehead;
	    (* add_opt_rrset nsec `NSEC `Authority; *)
	    `NoError
	      
      | `Delegated (sec, cutpoint) ->	  (* Name is delegated. *)
	    add_req_rrset cutpoint `NS `Authority; 
	    aa_flag := false; 
	    (* DNSSEC child zone keys *)
	    `NoError

      | `Wildcard (source, zonehead) ->	  (* Name is matched by a wildcard. *)
	    add_answer_rrsets qname source.rrsets qtype; 
	    add_opt_rrset zonehead `NS `Authority;
	    `NoError

      | `WildcardNSEC (source, zonehead, nsec) -> 
	    add_answer_rrsets qname source.rrsets qtype; 
	    add_opt_rrset zonehead `NS `Authority;
	    (* add_opt_rrset nsec `NSEC `Authority; *)
	    `NoError

      | `NXDomain (zonehead) ->		  (* Name doesn't exist. *)
	    add_negative_soa_rrset zonehead;
	    `NXDomain

      | `NXDomainNSEC (zonehead, nsec1, nsec2) ->
	    add_negative_soa_rrset zonehead;
	    (* add_opt_rrset nsec1 `NSEC `Authority; *)
	    (* add_opt_rrset nsec2 `NSEC `Authority; *)
	    `NXDomain
  in
  
  try 
    let rc = main_lookup qname qtype trie in	
    List.iter (fun (o, t) -> add_opt_rrset o t `Additional) !addqueue;
    { rcode = rc; aa = !aa_flag; 
      answer = !ans_rrs; authority = !auth_rrs; additional = !add_rrs }
  with 
      BadDomainName _ -> { rcode = `FormErr; aa = false; 
			               answer = []; authority = []; additional=[] }
    | TrieCorrupt ->  { rcode = `ServFail; aa = false;
		                answer = []; authority = []; additional=[] }

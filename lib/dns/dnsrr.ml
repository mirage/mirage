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
 * dnsrr.ml --- datatypes and handling for DNS RRs and RRSets
 *
 *)
  
(* Hash-consing: character strings *)
module CSH = Hashcons.Make (struct 
  type t = string 
  let equal a b = (a = b)
  let hash s = Hashtbl.hash s
end)
let cstr_hash = ref (CSH.create 101)
let hashcons_charstring s = CSH.hashcons !cstr_hash s

(* 
   Hash-consing: domain names (string lists).  This requires a little
   more subtlety than the Hashcons module gives us directly: we want to 
   merge common suffixes, and we're downcasing everything. 
   N.B. RFC 4343 says we shouldn't do this downcasing.
*)
module DNH = Hashcons.Make (struct 
  type t = string list
  let equal a b = (a = b)
  let hash s = Hashtbl.hash s
end)
let dn_hash = ref (DNH.create 101)
let rec hashcons_domainname = function 
    [] -> DNH.hashcons !dn_hash []
  | h :: t -> 
      let th = hashcons_domainname t 
      in DNH.hashcons !dn_hash 
	(((hashcons_charstring (String.lowercase h)).Hashcons.node) 
	 :: (th.Hashcons.node))

let clear_cons_tables () = 
  DNH.clear !dn_hash;
  CSH.clear !cstr_hash;
  dn_hash := DNH.create 1;
  cstr_hash := CSH.create 1

(* Mnemonicity! *)
type serial = int32
and ipv4 = int32
and cstr = string Hashcons.hash_consed

(* DNS node: everything we know about a domain name *)
and dnsnode = {
    owner: string list Hashcons.hash_consed;
    mutable rrsets: rrset list;
}

(* RRSet: TTL, type, and some number of rdata *)
and rrset = {
    ttl: int32;
    rdata: rdata; 
  }

and rdata = 
  | A of ipv4 list (* always length = 1 *)
  | NS of dnsnode list
(* MD and MF are obsolete; use MX for them *)
  | CNAME of dnsnode list
  | SOA of (dnsnode * dnsnode * serial * int32 * int32 * int32 * int32) list
  | MB of dnsnode list
  | MG of dnsnode list
  | MR of dnsnode list
  | WKS of (int32 * int * cstr) list 
  | PTR of dnsnode list
  | HINFO of (cstr * cstr) list
  | MINFO of (dnsnode * dnsnode) list
  | MX of (int * dnsnode) list 
  | TXT of (cstr list) list
  | RP of (dnsnode * dnsnode) list
  | AFSDB of (int * dnsnode) list
  | X25 of cstr list
  | ISDN of (cstr * cstr option) list
  | RT of (int * dnsnode) list
  | AAAA of cstr list
  | SRV of (int * int * int * dnsnode) list
  | UNSPEC of cstr list
  | Unknown of int * cstr list

(* XXX add other RR types *)
(* wire-domain type for non-rfc1035 rdata? *)


(* Extract relevant RRSets given a query type, a list of RRSets
   and a flag to say whether to return Cnames too *)
let get_rrsets qtype sets cnames_ok = 
  let match_rrset qtype set =
    match (qtype, set.rdata) with 
      (`A, A _) -> true
    | (`NS, NS _) -> true
    | (`CNAME, CNAME _) -> true
    | (`SOA, SOA _) -> true
    | (`MB, MB _) -> true
    | (`MG, MG _) -> true
    | (`MR, MR _) -> true
    | (`WKS, WKS _) -> true
    | (`PTR, PTR _) -> true
    | (`HINFO, HINFO _) -> true
    | (`MINFO, MINFO _) -> true
    | (`MX, MX _) -> true
    | (`TXT, TXT _) -> true
    | (`RP, RP _) -> true
    | (`AFSDB, AFSDB _) -> true
    | (`X25, X25 _) -> true
    | (`ISDN, ISDN _) -> true
    | (`RT, RT _) -> true
    | (`SRV, SRV _) -> true
    | (`AAAA, AAAA _) -> true
    | (`UNSPEC, UNSPEC _) -> true
    | (`Unknown (t1, _), Unknown (t2, _)) -> (t1 = t2)
    | (`MAILB, MB _) -> true
    | (`MAILB, MG _) -> true
    | (`MAILB, MR _) -> true
    | (`ANY, _) -> true
    | (_, CNAME _) -> cnames_ok
    | (_, _) -> false
  in List.filter (match_rrset qtype) sets



(* Merge a new RRSet into a list of RRSets. 
   Returns the new list and the ttl of the resulting RRset. 
   Reverses the order of the RRsets in the list *)
let merge_rrset new_rrset rrsets = 
  let cfn a b = compare (Hashtbl.hash a) (Hashtbl.hash b) in
  let mfn n o = List.merge cfn (List.fast_sort cfn n) o in
  let rec do_merge new_ttl new_rdata rrsets_done rrsets_rest = 
    match rrsets_rest with 
      | [] -> (new_ttl, { ttl = new_ttl; rdata = new_rdata } :: rrsets_done )
      | rrset :: rest -> match (new_rdata, rrset.rdata) with 
	      (A l1, A l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = A (mfn l1 l2) } :: rrsets_done))
          | (NS l1, NS l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = NS (mfn l1 l2) } :: rrsets_done))
          | (CNAME l1, CNAME l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = CNAME (mfn l1 l2) } :: rrsets_done))
          | (SOA l1, SOA l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = SOA (mfn l1 l2) } :: rrsets_done))
          | (MB l1, MB l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = MB (mfn l1 l2) } :: rrsets_done))
          | (MG l1, MG l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = MG (mfn l1 l2) } :: rrsets_done))
          | (MR l1, MR l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = MR (mfn l1 l2) } :: rrsets_done))
          | (WKS l1, WKS l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = WKS (mfn l1 l2) } :: rrsets_done))
          | (PTR l1, PTR l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = PTR (mfn l1 l2) } :: rrsets_done))
          | (HINFO l1, HINFO l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = HINFO (mfn l1 l2) } :: rrsets_done))
          | (MINFO l1, MINFO l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = MINFO (mfn l1 l2) } :: rrsets_done))
          | (MX l1, MX l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = MX (mfn l1 l2) } :: rrsets_done))
          | (TXT l1, TXT l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = TXT (mfn l1 l2) } :: rrsets_done))
          | (RP l1, RP l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = RP (mfn l1 l2) } :: rrsets_done))
          | (AFSDB l1, AFSDB l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = AFSDB (mfn l1 l2) } :: rrsets_done))
          | (X25 l1, X25 l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = X25 (mfn l1 l2) } :: rrsets_done))
          | (ISDN l1, ISDN l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = ISDN (mfn l1 l2) } :: rrsets_done))
          | (RT l1, RT l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = RT (mfn l1 l2) } :: rrsets_done))
          | (AAAA l1, AAAA l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = AAAA (mfn l1 l2) } :: rrsets_done))
          | (SRV l1, SRV l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = SRV (mfn l1 l2) } :: rrsets_done))
          | (UNSPEC l1, UNSPEC l2) ->
	        (rrset.ttl, List.rev_append rest
	          ({ ttl = rrset.ttl; rdata = UNSPEC (mfn l1 l2) } :: rrsets_done))
          | (Unknown (t1, l1), Unknown (t2, l2)) ->
	        if t1 = t2 then 
	          (rrset.ttl, List.rev_append rest
	            ({ ttl = rrset.ttl; rdata = Unknown (t1,(mfn l1 l2)) } 
		         :: rrsets_done))
	        else
	          do_merge new_ttl new_rdata (rrset :: rrsets_done) rest 
          | (_, _) -> do_merge new_ttl new_rdata (rrset :: rrsets_done) rest 
  in
  do_merge new_rrset.ttl new_rrset.rdata [] rrsets


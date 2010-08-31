(*
   dnsloader.mli -- how to build up a DNS trie from separate RRs
   Copyright (c) 2005-2006 Tim Deegan <tjd@phlegethon.org>
*)

(* Loader database: the DNS trie plus a hash table of other names in use *)
type db = { trie : Dnstrie.dnstrie; 
	    mutable names : (Dnstrie.key, Dnsrr.dnsnode) Hashtbl.t; } 

(* Make a new, empty database *)
val new_db : unit -> db

(* Call when guaranteed there will be no more updates *)
val no_more_updates : db -> unit

(* Insert RRs in the database: args are rdata, ttl, owner, db *)
val add_generic_rr : int -> string -> int32 -> string list -> db -> unit
val add_a_rr : Dnsrr.ipv4 -> int32 -> string list -> db -> unit
val add_ns_rr : string list -> int32 -> string list -> db -> unit
val add_cname_rr : string list -> int32 -> string list -> db -> unit
val add_soa_rr : 
    string list -> string list -> Dnsrr.serial -> 
      int32 -> int32 -> int32 -> int32 -> 
	int32 -> string list -> db -> unit
val add_mb_rr : string list -> int32 -> string list -> db -> unit
val add_mg_rr : string list -> int32 -> string list -> db -> unit
val add_mr_rr : string list -> int32 -> string list -> db -> unit
val add_wks_rr : int32 -> int -> string -> int32 -> string list -> db -> unit
val add_ptr_rr : string list -> int32 -> string list -> db -> unit
val add_hinfo_rr : string -> string -> int32 -> string list -> db -> unit
val add_minfo_rr : 
    string list -> string list -> int32 -> string list -> db -> unit
val add_mx_rr : int -> string list -> int32 -> string list -> db -> unit
val add_txt_rr : string list -> int32 -> string list -> db -> unit
val add_rp_rr :
    string list -> string list -> int32 -> string list -> db -> unit
val add_afsdb_rr : int -> string list -> int32 -> string list -> db -> unit
val add_x25_rr : string -> int32 -> string list -> db -> unit
val add_isdn_rr : string -> string option -> int32 -> string list -> db -> unit
val add_rt_rr : int -> string list -> int32 -> string list -> db -> unit
val add_aaaa_rr : string -> int32 -> string list -> db -> unit
val add_srv_rr :
  int -> int -> int -> string list -> int32 -> string list -> db -> unit
val add_unspec_rr : string -> int32 -> string list -> db -> unit


(* Raised if we already had an RRSet for this name and type, but with 
   a different TTL.  Also possible: Dnstrie.BadName.
   N.B. If TTLMismatch is raised, the RR was successfully added, and the RRSet
        now has the new ttl. *) 
exception TTLMismatch;;


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
val state : parserstate

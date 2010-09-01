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
 * dnstrie.mli -- interface to 256-way radix trie for DNS lookups 
 *
 *)

type dnstrie					(* Node of the trie *)
type key					(* Lookup key for the trie *)

exception BadDomainName of string	(* Malformed input to canon2key *)
exception TrieCorrupt			(* Missing data from a soa/cut node *)

(* Convert a canonical [ "www"; "example"; "com" ] domain name into a key 
   N.B. Requires that the input is already lower-case!  *)
val canon2key : string list -> key

(* Make a new, empty trie. *) 
val new_trie : unit -> dnstrie

(* Simple lookup function: just walk the trie *)
val simple_lookup : key -> dnstrie -> Dnsrr.dnsnode option

(* Look up a DNS entry in the trie, with full return *)
val lookup : key -> dnstrie ->
    [> `Delegated of bool * Dnsrr.dnsnode
     | `Found of bool * Dnsrr.dnsnode * Dnsrr.dnsnode
     | `NXDomain of Dnsrr.dnsnode
     | `NXDomainNSEC of Dnsrr.dnsnode * Dnsrr.dnsnode * Dnsrr.dnsnode
     | `NoError of Dnsrr.dnsnode
     | `NoErrorNSEC of Dnsrr.dnsnode * Dnsrr.dnsnode
     | `Wildcard of Dnsrr.dnsnode * Dnsrr.dnsnode
     | `WildcardNSEC of Dnsrr.dnsnode * Dnsrr.dnsnode * Dnsrr.dnsnode ]

(* Return the data mapped from this key, making new data if there is
   none there yet. *)
val lookup_or_insert : key -> dnstrie -> ?parent:dnstrie
  -> (unit -> Dnsrr.dnsnode) 
    -> Dnsrr.dnsnode

(* Sort out flags for a key's node: call after adding or removing 
   NS, SOA and KEY RRs  *)
val fix_flags : key -> dnstrie -> unit


(*
   dnstrie.ml -- 256-way radix trie for DNS lookups  
   Copyright (c) 2005-2006 Tim Deegan <tjd@phlegethon.org>      
*)

open Dnsrr;;

(* 
   Non-standard behaviour: 
    -- We don't support '\000' as a character in labels (because 
       it has a special meaning in the internal radix trie keys).
    -- We don't support RFC2673 bitstring labels.  Could be done but 
       they're not worth the bother: nobody uses them.
*)


type key = string;;			(* Type of a radix-trie key *)
exception BadDomainName of string;;	(* Malformed input to canon2key *)

(* Convert a canonical [ "www"; "example"; "com" ] domain name into a key.
   N.B. Requires that the input is already lower-case!  *)
let canon2key string_list = 
  let labelize s = 
    if String.contains s '\000' then 
      raise (BadDomainName "contains null character");
    if String.length s = 0 then 
      raise (BadDomainName "zero-length label");
    if String.length s > 63 then 
      raise (BadDomainName ("label too long: " ^ s));
    s 
  in List.fold_left (fun s l -> (labelize l) ^ "\000" ^ s) "" string_list

(* A "compressed" 256-way radix trie, with edge information provided
   explicitly in the trie nodes rather than with forward pointers. 
   
   For more details, read:
   Robert Sedgewick, "Algorithms", Addison Welsey, 1988. 
   Mehta and Sahni, eds., "Handbook of Data Structures and Applications", 
     Chapman and Hall, 2004. *)

module CTab = Hashtbl.Make (struct 
  type t = char 
  let equal a b = (a == b)
  let hash a = Hashtbl.hash a 
end)

type nodeflags = Nothing | Records | ZoneHead | SecureZoneHead | Delegation
and dnstrie = {
    mutable data: dnsnode option;	(* RRSets etc. *)
    mutable edge: string;	       	(* Upward edge label *)
    mutable byte: int;		       	(* Byte of key to branch on *)
    mutable children: dnstrie array;	(* Downward edges *)
    mutable ch_key: string;		(* Characters tagging each edge *)
    mutable least_child: char;		(* Smallest key of any child *)
    mutable flags: nodeflags;		(* Kinds of records held here *)
  }

let bad_node = { data = None; edge = ""; byte = -1; 
		 children = [||]; ch_key = ""; least_child = '\255';
		 flags = Nothing; }

exception TrieCorrupt			(* Missing data from a soa/cut node *)


(* Utility for trie ops: compare the remaining bytes of key with the 
   inbound edge to this trie node *)
let cmp_edge node key =  
  let edgelen = String.length node.edge in
  let offset = node.byte - edgelen in
  let keylen = String.length key - offset in
  let cmplen = min edgelen keylen in 
  let cmpres = String.compare (String.sub node.edge 0 cmplen) 
                              (String.sub key offset cmplen) in
  if cmpres = 0 then begin
    if keylen >= edgelen then 
      `Match       (* The key matches and reaches the end of the edge *)
    else 
      `OutOfKey    (* The key matches but runs out before the edge finishes *)
  end 
  else if cmpres < 0 then
    `ConflictGT  (* The key deviates from the edge, and is "greater" than it *)
  else (* cmpres > 0 *)
    `ConflictLT  (* The key deviates from the edge *)


(* Utility for trie ops: number of matching characters *)
let get_match_length trie key = 
  let rec match_r edge key n off =
    try
      if edge.[n] = key.[n + off] then match_r edge key (n + 1) off
      else n
    with
      Invalid_argument _ -> n
  in
  let offset = trie.byte - (String.length trie.edge) in 
  match_r trie.edge key 0 offset 


(* Child table management: arrays*)
let new_child_table () = Array.copy [||]

let children_iter f node =
  let ch_count = Array.length node.children in
  assert (ch_count == String.length node.ch_key);
  for i = 0 to (ch_count - 1) do 
    f node.ch_key.[i] node.children.(i)
  done

let child_lookup char node = 
  let ch_count = Array.length node.children in
  assert (ch_count == String.length node.ch_key);
  let rec lfn i = 
    if (i >= ch_count) then None
    else if node.ch_key.[i] = char then Some node.children.(i)
    else lfn (i + 1) 
  in lfn 0 

let child_update node char child = 
  let ch_count = Array.length node.children in
  assert (ch_count == String.length node.ch_key);
  let rec ufn i = 
    if (i >= ch_count) then true
    else if node.ch_key.[i] = char then
      begin node.children.(i) <- child; false end
    else ufn (i + 1) 
  in if ufn 0 then 
    begin
      node.children <- Array.append node.children (Array.make 1 child);
      node.ch_key <- (node.ch_key ^ (String.make 1 char))
    end

let child_delete node char = 
  let ch_count = Array.length node.children in
  assert (ch_count == String.length node.ch_key);
  try 
    let i = String.index node.ch_key char in 
    node.ch_key <- ((String.sub node.ch_key 0 i) 
                    ^ (String.sub node.ch_key (i+1) (ch_count - (i+1))));
    node.children <- (Array.append
			(Array.sub node.children 0 i) 
			(Array.sub node.children (i+1) (ch_count - (i+1))));
  with Not_found -> ()

let child_lookup_less_than char node = 
  let ch_count = Array.length node.children in
  assert (ch_count == String.length node.ch_key);
  let rv = ref None in 
  let rc = ref '\000' in 
  let ifn c n = 
    if c >= !rc && c < char then begin rc := c; rv := Some n end
  in children_iter ifn node;
  !rv

let child_count node = 
  Array.length node.children

let only_child node = 
  assert (Array.length node.children = 1);
  node.children.(0)


(* Assert that this value exists: not every trie node needs to hold data, 
   but some do, and this allows us to discard the "option" when we know
   it's safe *)
let not_optional = function 
    Some x -> x
  | None -> raise TrieCorrupt


(* Make a new, empty trie *)
let new_trie () =
  let rec n = { data = None;
                edge = "";
                byte = 0;
                children = [||];
		ch_key = "";
		least_child = '\255';
                flags = Nothing;
              } in n


(* Simple lookup function: just walk the trie *)
let rec simple_lookup key node = 
  if not (cmp_edge node key = `Match) then None
  else if ((String.length key) = node.byte) then node.data
  else match (child_lookup key.[node.byte] node) with
    None -> None
  | Some child -> simple_lookup key child


(* DNS lookup function *)
let lookup key trie =
  
  (* Variables we keep track of all the way down *)
  let last_soa = ref bad_node in	(* Last time we saw a zone head *)
  let last_cut = ref trie in		(* Last time we saw a cut point *)
  let last_lt = ref trie in		(* Last time we saw something < key *)
  let last_rr = ref trie in		(* Last time we saw any data *)
  let secured = ref false in		(* Does current zone use DNSSEC? *)

  (* DNS lookup function, part 4: DNSSEC authenticated denial *)
  let lookup_nsec key = 
    (* Follow the trie down to the right as far as we can *)
    let rec find_largest node = 
      let lc = ref '\000' in 
      let child = ref node in 
      let ifn c node = if c >= !lc then begin lc := c; child := node end in 
      children_iter ifn node;
      if !child = node then node
      else find_largest !child
    in
    let ch = key.[!last_lt.byte] in
    (* last_lt is the last chance we had to go to the left: could be for a
       number of reasons *)
    if not (cmp_edge !last_lt key = `Match) then 
      find_largest !last_lt		(* All of last_lt is < key *)
    else if ch <= !last_lt.least_child then
      !last_lt				(* Only last_lt itself is < key *)
    else (* Need to find the largest child less than key *)
      let lc = ref !last_lt.least_child in 
      let ln = ref !last_lt in 
      let ifn c node = 
	if c >= !lc && c < ch then begin lc := c; ln := node end in 
      children_iter ifn !last_lt;
      find_largest !ln
  in


  (* DNS lookup function, part 3: wildcards. *)
  let lookup_wildcard key last_branch =

    (* Find the offset of the last '\000' in the key *)
    let rec previous_break key n = 
      if n < 0 then -1 else match key.[n] with 
	'\000' -> n
      | _ -> previous_break key (n - 1)
    in 

    (* Find the offset of the "Closest Encounter" in the key *)
    let closest_encounter key last_branch = 
      let first_bad_byte = (last_branch.byte - String.length last_branch.edge) 
	  + get_match_length last_branch key in
      previous_break key first_bad_byte
    in 
    
    (* Lookup, tracking only the "last less-than" node *)
    let rec wc_lookup_r key node = 
      match (cmp_edge node key) with
	`ConflictGT -> last_lt := node; None
      | `ConflictLT | `OutOfKey -> None
      | `Match -> 
	  if ((String.length key) = node.byte) 
	  then node.data
	  else begin
	    if not (node.data = None) || node.least_child < key.[node.byte] 
	    then last_lt := node; 
	    match (child_lookup key.[node.byte] node) with
	      None -> None
	    | Some child -> simple_lookup key child
	  end
    in

    (* Find the source of synthesis, and look it up *)
    let byte = (closest_encounter key last_branch) + 1 in 
    let ss_key = String.sub key 0 byte ^ "*\000" in
    (ss_key, wc_lookup_r ss_key !last_rr)
  in
  
  
  (* DNS lookup function, part 2a: gather NSECs and wildcards *)
  let lookup_failed key last_branch = 
    if (!last_cut.byte > !last_soa.byte) 
    then `Delegated (!secured, not_optional !last_cut.data)
    else begin 
      if !secured then
	let nsec1 = lookup_nsec key in
	match lookup_wildcard key last_branch with 
	  (_, Some dnsnode) -> `WildcardNSEC (dnsnode, 
					      not_optional !last_soa.data,
					      not_optional nsec1.data)
	| (ss_key, None) -> let nsec2 = lookup_nsec ss_key in 
	  `NXDomainNSEC (not_optional !last_soa.data,
			 not_optional nsec1.data, not_optional nsec2.data)
      else 
	(* No DNSSEC: simple answers. *)
	match lookup_wildcard key last_branch with 
	  (k, Some dnsnode) -> `Wildcard (dnsnode, not_optional !last_soa.data)
	| (k, None) -> `NXDomain (not_optional !last_soa.data)
    end
  in


  (* DNS lookup function, part 2b: gather NSEC for NoError *)
  let lookup_noerror key  = 
    if (!last_cut.byte > !last_soa.byte) 
    then `Delegated (!secured, not_optional !last_cut.data)
    else begin
      if !secured then
	(* Look for the NSEC RR that covers this name.  RFC 4035 says we
	   might need another one to cover possible wildcards, but since this
	   name "exists", the "Next Domain Name" field of the NSEC RR will 
	   be a child of this name, proving that it can't match any wildcard *)
	let nsec = lookup_nsec key in
	`NoErrorNSEC (not_optional !last_soa.data, not_optional nsec.data)
      else
	`NoError (not_optional !last_soa.data)
    end
  in


  (* DNS lookup function, part 1: finds the node that holds any data
     stored with this key, and tracks last_* for use in DNSSEC and wildcard 
     lookups later. *)
  let rec lookup_r key node last_branch =
    match cmp_edge node key with 
      `ConflictLT -> lookup_failed key last_branch
    | `ConflictGT -> last_lt := node; lookup_failed key last_branch
    | `OutOfKey -> lookup_noerror key 
    | `Match -> 
	begin 
	  begin 
	    match node.flags with 
	      Nothing -> () 
	    | Records -> last_rr := node
	    | ZoneHead -> last_rr := node; 
		last_soa := node; last_cut := node; secured := false
	    | SecureZoneHead -> last_rr := node; 
		last_soa := node; last_cut := node; secured := true
	    | Delegation -> last_rr := node; last_cut := node
	  end;
	  if ((String.length key) = node.byte) then 
	    match node.data with 
	      Some answer -> 
		if (!last_cut.byte > !last_soa.byte) 
		then `Delegated (!secured, not_optional !last_cut.data)
		else `Found (!secured, answer, not_optional !last_soa.data)
	    | None -> lookup_noerror key 
	  else begin
	    if not (node.data = None) || node.least_child < key.[node.byte] 
	    then last_lt := node; 
	    match (child_lookup key.[node.byte] node) with
      	      None -> lookup_failed key node
	    | Some child -> 
		begin 
		  assert (child.byte > node.byte);
		  lookup_r key child node
		end
	  end
	end
  in

  lookup_r key trie trie




(* Return the data mapped from this key, making new data if there is
   none there yet. *)
let rec lookup_or_insert key trie ?(parent = trie) factory =
  let get_data_or_call_factory node = 
    match node.data with 
      Some d -> d
    | None -> 
	let d = factory () in 
	node.data <- Some d; 
	assert (node.flags = Nothing); 
	node.flags <- Records; 
	d 
  in
  if not (cmp_edge trie key = `Match) then begin
    (* Need to break this edge into two pieces *)
    let match_len = get_match_length trie key in
    let rest_len = String.length trie.edge - match_len in 
    let branch = { data = None; 
		   edge = String.sub trie.edge 0 match_len;
		   byte = trie.byte - rest_len;
		   children = [||];
		   ch_key = "";
		   least_child = trie.edge.[match_len];
		   flags = Nothing;
		 } in
    (* Order of the next two lines is important *)
    child_update parent branch.edge.[0] branch;
    trie.edge <- String.sub trie.edge match_len rest_len;
    child_update branch trie.edge.[0] trie;
    (* Don't need to update parent.least_child *)
    lookup_or_insert key branch ~parent:parent factory
  end else begin
    let length_left = (String.length key) - trie.byte in 
    if length_left = 0 then 
      get_data_or_call_factory trie 
    else begin 
      match (child_lookup key.[trie.byte] trie) with
      	Some child -> begin
	  lookup_or_insert key child ~parent:trie factory
      	end 
      | None -> let child = { data = None; 
			      edge = String.sub key trie.byte length_left;
			      byte = String.length key;
			      children = [||];
			      ch_key = "";
			      least_child = '\255';
			      flags = Nothing;
			    } in 
	assert (child.edge.[0] = key.[trie.byte]);
	child_update trie child.edge.[0] child;
	trie.least_child <- min trie.least_child key.[trie.byte];
      	get_data_or_call_factory child
    end
  end



(* Sort out flags for a key's node; call after inserting significant RRs *)
let rec fix_flags key node = 
  let soa = ref false in 
  let ns = ref false in 
  let dnskey = ref false in 

  let rec set_flags node rrset =
    match rrset.rdata with 
      SOA _   -> soa := true 
    | NS _    -> ns := true 
 (* | DNSKEY _ -> dnskey := true *)
    | _        -> ()
  in

  if not (cmp_edge node key = `Match) then ()
  else if ((String.length key) = node.byte) then begin
    match node.data with 
      None -> node.flags <- Nothing
    | Some dnsnode -> List.iter (set_flags node) dnsnode.rrsets;
	if !soa then 
	  if !dnskey then 
	    node.flags <- SecureZoneHead
	  else
	    node.flags <- ZoneHead
	else if !ns then 
	  node.flags <- Delegation 
	else
	  node.flags <- Records
  end else match (child_lookup key.[node.byte] node) with
    None -> ()
  | Some child -> fix_flags key child


(* Delete all the data associated with a key *)
let rec delete key ?(gparent = None) ?(parent = None) node = 
  if not (cmp_edge node key = `Match) then ()
  else if ((String.length key) != node.byte) then
    begin 
      match (child_lookup key.[node.byte] node) with
	None -> ()
      | Some child -> delete key ~gparent:parent ~parent:(Some node) child
    end

  else let collapse_node p n = 
    let c = only_child n in 
    c.edge <- (n.edge ^ c.edge);
    child_update p c.edge.[0] c

  in begin   
    node.data <- None;
    match parent with None -> () | Some p -> 
      match child_count node with
	1 -> collapse_node p node
      | 0 -> 
	  begin 
	    child_delete p node.edge.[0];
	    if ((p.data = None) && (child_count p = 1)) then 
	      match gparent with None -> () | Some gp -> collapse_node gp p
	  end
      | _ -> ()
  end

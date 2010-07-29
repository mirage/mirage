(*
 * Copyright (c) 2005 Anil Madhavapeddy <anil@recoil.org>
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
 * $Id: mpl_utils.ml,v 1.9 2005/11/23 23:34:31 avsm Exp $
 *)

(* Maintain a list of values to a key in a hashtable *)
let hashtbl_add_list h k v =
    try
        let i = Hashtbl.find h k in
        Hashtbl.replace h k (v :: i)
    with Not_found ->
        Hashtbl.add h k [v] 

(* 2 ^ val - 1 *)
let tworaised x =
	(int_of_float (2. ** (float_of_int x))) - 1
(*
 function
	|0 -> 0
	|x -> (int_of_float (2. ** (float_of_int (x-1)))) + (tworaised (x-1))
*)

(* Returns unique version of list, unsorted *)
let list_unique l =
  let h = Hashtbl.create 1 in
  List.iter (fun k -> Hashtbl.replace h k ()) l;
  Hashtbl.fold (fun k v a -> k :: a) h []

(* Returns unique list, maintains order, drops later entries *)
let list_unique_s l =
    let h = Hashtbl.create 1 in
    List.rev (List.fold_left (fun a b -> 
        if Hashtbl.mem h b then a else (Hashtbl.add h b (); b::a)) [] l)

let list_filter_map fn l =
    let x = List.map fn l in
    List.fold_left (fun a -> function |None -> a |Some x -> x::a) [] x

(* Chop a filename extension if it exists, otherwise do nothing *)
let safe_chop f =
    try
        Filename.chop_extension f
    with Invalid_argument _ -> f

let may fn = function
    |None -> ()
    |Some x -> fn x

let must fn = function
    |None -> failwith "must"
    |Some x -> fn x

let iter2i fn la lb =
    let c = ref 0 in
    List.iter2 (fun a b ->
        fn !c a b;
        incr c) la lb

let fold_stop fn =
    List.fold_left (fun a b ->
        match a with
        |None -> fn b
        |Some _ as x -> x
    ) None

let assoc_opt v l =
    try
        Some (List.assoc v l)
    with
    |Not_found -> None

(* Just use a global variable for recording our log level in here *)
module Logger = struct
    type level =
    |Quiet
    |Normal
    |Verbose
    
    let level = ref Normal
    
    let set_log_level l = level := l
    
    let logfn l s =
        let out () = prerr_endline s in
        match l with
        |Quiet -> out ()
        |Normal -> if !level != Quiet then out ()
        |Verbose -> if !level != Quiet && !level != Normal then out ()
        
    let log_quiet = logfn Quiet
    let log = logfn Normal
    let log_verbose = logfn Verbose
end

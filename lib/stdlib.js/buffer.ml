open Pervasives
(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*   Pierre Weis and Xavier Leroy, projet Cristal, INRIA Rocquencourt  *)
(*                                                                     *)
(*  Copyright 1999 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)

(* $Id: buffer.ml 10216 2010-03-28 08:16:45Z xleroy $ *)

(* Extensible buffers *)

open Ocamljs.Inline

type a

type t = {
  array : a;
  mutable string : string option;
  mutable length : int;
}

let create n = {
  array = << new Array() >>;
  string = None;
  length = 0;
}

let contents b =
  match b.string with
    | None -> let s = << $b.array$.join('') >> in b.string <- Some s; s
    | Some s -> s

let sub b ofs len =
  if ofs < 0 || len < 0 || ofs > b.length - len
  then invalid_arg "Buffer.sub";
  let s = contents b in
  << $s$.substring($ofs$, $ofs$ + $len$) >>

let blit src srcoff dst dstoff len =
  failwith "unimplemented" (* XXX *)
(*
  if len < 0 || srcoff < 0 || srcoff > src.position - len
             || dstoff < 0 || dstoff > (String.length dst) - len
  then invalid_arg "Buffer.blit"
  else
    String.blit src.buffer srcoff dst dstoff len
;;
*)

let nth b ofs =
  if ofs < 0 || ofs >= b.length
  then invalid_arg "Buffer.nth";
  let s = contents b in
  << $s$.charCodeAt($ofs$) >>

let length b = b.length

let clear b =
  b.length <- 0;
  <:stmt< $b.array$.length = 0; >>

let reset = clear

let add_char b c =
  b.string <- None;
  b.length <- b.length + 1;
  <:stmt< $b.array$.push(String.fromCharCode($c$)); >>

let add_substring b s offset len =
  if offset < 0 || len < 0 || offset > String.length s - len
  then invalid_arg "Buffer.add_substring";
  b.string <- None;
  b.length <- b.length + len;
  <:stmt< $b.array$.push($s$.substring($offset$, $offset$ + $len$)); >>

let add_string b s =
  b.string <- None;
  b.length <- b.length + String.length s;
  <:stmt< $b.array$.push($s$); >>

let add_buffer b bs =
  add_string b (contents bs)

let add_channel b ic len =
  failwith "unsupported"

let output_buffer oc b =
  failwith "unsupported"

let closing = function
  | '(' -> ')'
  | '{' -> '}'
  | _ -> assert false;;

(* opening and closing: open and close characters, typically ( and )
   k: balance of opening and closing chars
   s: the string where we are searching
   start: the index where we start the search. *)
let advance_to_closing opening closing k s start =
  let rec advance k i lim =
    if i >= lim then raise Not_found else
    if s.[i] = opening then advance (k + 1) (i + 1) lim else
    if s.[i] = closing then
      if k = 0 then i else advance (k - 1) (i + 1) lim
    else advance k (i + 1) lim in
  advance k start (String.length s);;

let advance_to_non_alpha s start =
  let rec advance i lim =
    if i >= lim then lim else
    match s.[i] with
    | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' |
      'é'|'à'|'á'|'è'|'ù'|'â'|'ê'|
      'î'|'ô'|'û'|'ë'|'ï'|'ü'|'ç'|
      'É'|'À'|'Á'|'È'|'Ù'|'Â'|'Ê'|
      'Î'|'Ô'|'Û'|'Ë'|'Ï'|'Ü'|'Ç' ->
      advance (i + 1) lim
    | _ -> i in
  advance start (String.length s);;

(* We are just at the beginning of an ident in s, starting at start. *)
let find_ident s start lim =
  if start >= lim then raise Not_found else
  match s.[start] with
  (* Parenthesized ident ? *)
  | '(' | '{' as c ->
     let new_start = start + 1 in
     let stop = advance_to_closing c (closing c) 0 s new_start in
     String.sub s new_start (stop - start - 1), stop + 1
  (* Regular ident *)
  | _ ->
     let stop = advance_to_non_alpha s (start + 1) in
     String.sub s start (stop - start), stop;;

(* Substitute $ident, $(ident), or ${ident} in s,
    according to the function mapping f. *)
let add_substitute b f s =
  let lim = String.length s in
  let rec subst previous i =
    if i < lim then begin
      match s.[i] with
      | '$' as current when previous = '\\' ->
         add_char b current;
         subst ' ' (i + 1)
      | '$' ->
         let j = i + 1 in
         let ident, next_i = find_ident s j lim in
         add_string b (f ident);
         subst ' ' next_i
      | current when previous == '\\' ->
         add_char b '\\';
         add_char b current;
         subst ' ' (i + 1)
      | '\\' as current ->
         subst current (i + 1)
      | current ->
         add_char b current;
         subst current (i + 1)
    end else
    if previous = '\\' then add_char b previous in
  subst ' ' 0;;

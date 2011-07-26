(* Bitstring syntax extension.
 * Copyright (C) 2008 Red Hat Inc., Richard W.M. Jones
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 * $Id: bitstring_objinfo.ml 142 2008-07-17 15:45:56Z richard.wm.jones $
 *)

open Printf

open Bitstring
module P = Bitstring_persistent

let () =
  if Array.length Sys.argv <= 1 then
    failwith "bitstring-objinfo filename.bmpp";
  let filename = Sys.argv.(1) in
  let chan = open_in filename in
  let names = ref [] in
  (try
     let rec loop () =
       let name = P.named_from_channel chan in
       names := name :: !names
     in
     loop ()
   with End_of_file -> ()
  );
  close_in chan;
  let names = List.rev !names in
  List.iter (
    function
    | name, P.Pattern patt ->
	printf "let bitmatch %s =\n%s\n"
	  name (P.string_of_pattern patt)
    | name, P.Constructor cons ->
	printf "let BITSTRING %s =\n%s\n"
	  name (P.string_of_constructor cons)
  ) names

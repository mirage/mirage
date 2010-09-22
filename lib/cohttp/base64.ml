(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 *               2010 Thomas Gazagnaire <thomas@gazagnaire.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

let code = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
let padding = '='

let of_char x = if x = padding then 0 else String.index code x

let to_char x = code.[x]

let decode x = 
  let words = String.length x / 4 in
  let padding = 
    if String.length x = 0 then 0 else (
    if x.[String.length x - 2] = padding
    then 2 else (if x.[String.length x - 1] = padding then 1 else 0)) in
  let output = String.make (words * 3 - padding) '\000' in
  for i = 0 to words - 1 do
    let a = of_char x.[4 * i + 0]
    and b = of_char x.[4 * i + 1]
    and c = of_char x.[4 * i + 2]
    and d = of_char x.[4 * i + 3] in
    let n = (a lsl 18) lor (b lsl 12) lor (c lsl 6) lor d in
    let x = (n lsr 16) land 255
    and y = (n lsr 8) land 255
    and z = n land 255 in
    output.[3 * i + 0] <- char_of_int x;
    if i <> words - 1 || padding < 2 then output.[3 * i + 1] <- char_of_int y;
    if i <> words - 1 || padding < 1 then output.[3 * i + 2] <- char_of_int z;
  done;
  output

let encode x = 
  let length = String.length x in
  let words = (length + 2) / 3 in (* rounded up *)
  let padding = if length mod 3 = 0 then 0 else 3 - (length mod 3) in
  let output = String.make (words * 4) '\000' in
  let get i = if i >= length then 0 else int_of_char x.[i] in
  for i = 0 to words - 1 do
    let x = get (3 * i + 0)
    and y = get (3 * i + 1)
    and z = get (3 * i + 2) in
    let n = (x lsl 16) lor (y lsl 8) lor z in 
    let a = (n lsr 18) land 63
    and b = (n lsr 12) land 63
    and c = (n lsr 6) land 63
    and d = n land 63 in
    output.[4 * i + 0] <- to_char a;
    output.[4 * i + 1] <- to_char b;
    output.[4 * i + 2] <- to_char c;
    output.[4 * i + 3] <- to_char d;
  done;
  for i = 1 to padding do
    output.[String.length output - i] <- '=';
  done;
  output

let test x = 
  let x' = encode x in
  let x'' = decode x' in
  if x <> x'' 
  then failwith (Printf.sprintf "Original: '%s'; encoded = '%s'; decoded = '%s'" x x' x'')

let tests = [ "hello"; 
	      "this is a basic test"; "1"; "22"; "333"; "4444"; "5555";
	      "\000"; "\000\000"; "\000\000\000"; "\000\000\000\000" ]

(*
let _ = List.iter test tests
*)

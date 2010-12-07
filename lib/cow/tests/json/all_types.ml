(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
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

type t = Foo of int | Bar of (int * float) with json

module M = struct
	type m = t with json
end

(* XXX: support 'a t *)
type x = {
	foo: M.m;
	bar: string;
	gna: float list;
	f1: (int option * bool list * float list list) option;
	f2: (string * string list) array;
	f3: int32;
	f4: int64;
	f5: int;
	f6: (unit * char) list;
	f7: t list;
	progress: int array;
 } with json

let run () =
	let x = {
		foo= Foo 3;
		bar= "ha          ha";
		gna=[1.; 2.; 3.; 4. ];
		f2 = [| "hi",["hi"]; "hou",["hou";"hou"]; "foo", ["b";"a";"r"] |];
		f1 = Some (None, [true], [[1.]; [2.;3.]]);
		f3 = Int32.max_int;
		f4 = Int64.max_int;
		f5 = max_int;
		f6 = [ (),'a' ; (),'b' ; (),'c'; (),'d' ; (),'e' ];
		f7 = [ Foo 1; Foo 2; Foo 3 ];
		progress = [| 0; 1; 2; 3; 4; 5 |];
	} in

	Printf.printf "Testing basic marshalling/unmarshalling for JSON:\n"
	
	let json = json_of_x_m x in
	Printf.printf "\n==json==\n%s\n" (Json.to_string json);

  let x_json = x_of_json json in
	Printf.printf "\n==Sanity check 1==\nx=x_json: %b\n" (x = x_json);
	assert (x = x_json)


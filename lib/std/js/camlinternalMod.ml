open Pervasives
(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*         Xavier Leroy, projet Cristal, INRIA Rocquencourt            *)
(*                                                                     *)
(*  Copyright 2004 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)

(* $Id: camlinternalMod.ml 8768 2008-01-11 16:13:18Z doligez $ *)

type shape =
  | Function
  | Lazy
  | Class
  | Module of shape array

let rec init_mod loc shape =
  match shape with
  | Function ->
      Obj.repr (fun _ -> raise (Undefined_recursive_module loc))
  | Lazy ->
      Obj.repr (lazy (raise (Undefined_recursive_module loc)))
  | Class ->
      Obj.repr (CamlinternalOO.dummy_class loc)
  | Module comps ->
      Obj.repr (Array.map (init_mod loc) comps)

let rec update_mod shape o n =
  match shape with
    | Module comps ->
        assert (Obj.tag n = 0 && Obj.size n >= Array.length comps);
        for i = 0 to Array.length comps - 1 do
          match comps.(i) with
            | Module _ -> update_mod comps.(i) (Obj.field o i) (Obj.field n i)
            | _ -> Obj.set_field o i (Obj.field n i)
        done
    | _ -> assert false

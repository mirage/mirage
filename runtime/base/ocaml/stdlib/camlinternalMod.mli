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

(* $Id: camlinternalMod.mli 6586 2004-08-12 12:57:00Z xleroy $ *)

type shape =
  | Function
  | Lazy
  | Class
  | Module of shape array

val init_mod: string * int * int -> shape -> Obj.t
val update_mod: shape -> Obj.t -> Obj.t -> unit

(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the Q Public License version 1.0.               *)
(*                                                                     *)
(***********************************************************************)

(* $Id: compile.mli 6395 2004-06-13 12:46:41Z xleroy $ *)

(* Compile a .ml or .mli file *)

open Format

val interface: formatter -> string -> string -> unit
val implementation: formatter -> string -> string -> unit
val c_file: string -> unit

val initial_env: unit -> Env.t
val init_path: unit -> unit

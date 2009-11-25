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

(* $Id: runtimedef.mli,v 1.4 1999/11/17 18:57:01 xleroy Exp $ *)

(* Values and functions known and/or provided by the runtime system *)

val builtin_exceptions: string array
val builtin_primitives: string array

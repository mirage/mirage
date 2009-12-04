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

(* $Id: closure.mli,v 1.5 1999/11/17 18:56:30 xleroy Exp $ *)

(* Introduction of closures, uncurrying, recognition of direct calls *)

val intro: int -> Lambda.lambda -> Clambda.ulambda


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

(* $Id: reload.mli,v 1.6 1999/11/17 18:56:35 xleroy Exp $ *)

(* Insert load/stores for pseudoregs that got assigned to stack locations. *)

val fundecl: Mach.fundecl -> Mach.fundecl * bool


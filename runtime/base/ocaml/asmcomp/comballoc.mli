(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1999 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the Q Public License version 1.0.               *)
(*                                                                     *)
(***********************************************************************)

(* $Id: comballoc.mli,v 1.2 1999/11/17 18:56:32 xleroy Exp $ *)

(* Combine heap allocations occurring in the same basic block *)

val fundecl: Mach.fundecl -> Mach.fundecl

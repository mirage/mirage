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

(* $Id: liveness.mli,v 1.5 2000/04/21 08:10:33 weis Exp $ *)

(* Liveness analysis.
   Annotate mach code with the set of regs live at each point. *)

open Format

val fundecl: formatter -> Mach.fundecl -> unit

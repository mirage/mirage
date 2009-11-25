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

(* $Id: scheduling.ml,v 1.2 1999/11/17 18:56:45 xleroy Exp $ *)

open Schedgen (* to create a dependency *)

(* No scheduling is needed for the Mips, the assembler
   does it better than us.  *)

let fundecl f = f

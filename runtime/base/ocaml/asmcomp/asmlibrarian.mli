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

(* $Id: asmlibrarian.mli,v 1.6 2000/04/21 08:10:27 weis Exp $ *)

(* Build libraries of .cmx files *)

open Format

val create_archive: string list -> string -> unit

type error =
    File_not_found of string
  | Archiver_error of string

exception Error of error

val report_error: formatter -> error -> unit

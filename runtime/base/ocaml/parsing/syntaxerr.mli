(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1997 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the Q Public License version 1.0.               *)
(*                                                                     *)
(***********************************************************************)

(* $Id: syntaxerr.mli 2908 2000-03-06 22:12:09Z weis $ *)

(* Auxiliary type for reporting syntax errors *)

open Format

type error =
    Unclosed of Location.t * string * Location.t * string
  | Other of Location.t

exception Error of error
exception Escape_error

val report_error: formatter -> error -> unit

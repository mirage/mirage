(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*          Damien Doligez, projet Moscova, INRIA Rocqencourt          *)
(*                                                                     *)
(*  Copyright 2002 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the Q Public License version 1.0.               *)
(*                                                                     *)
(***********************************************************************)

(* $Id: int64ops.mli 5200 2002-10-29 17:53:24Z doligez $ *)

(****************** arithmetic operators for Int64 *********************)

val ( ++ ) : int64 -> int64 -> int64;;
val ( -- ) : int64 -> int64 -> int64;;
val suc64 : int64 -> int64;;
val pre64 : int64 -> int64;;
val _0 : int64;;
val _1 : int64;;
val _minus1 : int64;;
val ( ~~ ) : string -> int64;;
val max_small_int : int64;;
val to_int : int64 -> int;;

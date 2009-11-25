(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*      Damien Doligez and Francois Rouaix, INRIA Rocquencourt         *)
(*   Ported to Objective Caml by John Malecki and Xavier Leroy         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)

(* $Id: profiling.mli,v 1.6 2005/03/24 17:20:54 doligez Exp $ *)

(* Run-time library for profiled programs *)

val counters: (string * (string * int array)) list ref;;
val incr: int array -> int -> unit;;

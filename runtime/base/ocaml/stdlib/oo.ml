(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*         Jerome Vouillon, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)

(* $Id: oo.ml 6331 2004-05-26 11:10:52Z garrigue $ *)

let copy = CamlinternalOO.copy
external id : < .. > -> int = "%field1"
let new_method = CamlinternalOO.public_method_label
let public_method_label = CamlinternalOO.public_method_label

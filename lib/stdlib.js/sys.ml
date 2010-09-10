open Pervasives
(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)

(* $Id: sys.mlp,v 1.2 2007/02/26 14:21:57 xleroy Exp $ *)

(* System interface *)

external get_config: unit -> string * int = "caml_sys_get_config"
external get_argv: unit -> string * string array = "caml_sys_get_argv"

let (executable_name, argv) = get_argv()
let (os_type, word_size) = get_config()
let max_array_length = (1 lsl (word_size - 10)) - 1;;
let max_string_length = word_size / 8 * max_array_length - 1;;

external time: unit -> float = "caml_sys_time"

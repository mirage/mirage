(*************************************************************************)
(*                                                                       *)
(*                Objective Caml LablTk library                          *)
(*                                                                       *)
(*            Jacques Garrigue, Kyoto University RIMS                    *)
(*                                                                       *)
(*   Copyright 1999 Institut National de Recherche en Informatique et    *)
(*   en Automatique and Kyoto University.  All rights reserved.          *)
(*   This file is distributed under the terms of the GNU Library         *)
(*   General Public License, with the special exception on linking       *)
(*   described in file ../../../LICENSE.                                 *)
(*                                                                       *)
(*************************************************************************)

(* $Id: jg_message.mli,v 1.10 2002/07/26 00:04:05 garrigue Exp $ *)

open Widget

val formatted :
  title:string ->
  ?on:frame widget ->
  ?ppf:Format.formatter ->
  ?width:int ->
  ?maxheight:int ->
  ?minheight:int ->
  unit -> any widget * text widget * (unit -> unit)

val ask :
    title:string -> ?master:toplevel widget ->
    ?no:bool -> ?cancel:bool -> string -> [`Cancel|`No|`Yes]

val info :
    title:string -> ?master:toplevel widget -> string -> unit

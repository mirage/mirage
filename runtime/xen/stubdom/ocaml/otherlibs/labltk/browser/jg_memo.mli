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

(* $Id: jg_memo.mli,v 1.7 2001/12/07 13:39:59 xleroy Exp $ *)

val fast : f:('a -> 'b) -> 'a -> 'b
(* "fast" memoizer: uses a List.assq like function      *)
(* Good for a smallish number of keys, phisically equal *)

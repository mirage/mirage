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

(* $Id: digest.mli 7164 2005-10-25 18:34:07Z doligez $ *)

(** MD5 message digest.

   This module provides functions to compute 128-bit ``digests'' of
   arbitrary-length strings or files. The digests are of cryptographic
   quality: it is very hard, given a digest, to forge a string having
   that digest. The algorithm used is MD5.
*)

type t = string
(** The type of digests: 16-character strings. *)

val string : string -> t
(** Return the digest of the given string. *)

val substring : string -> int -> int -> t
(** [Digest.substring s ofs len] returns the digest of the substring
   of [s] starting at character number [ofs] and containing [len]
   characters. *)

val file : string -> t
(** Return the digest of the file whose name is given. *)

val to_hex : t -> string
(** Return the printable hexadecimal representation of the given digest. *)

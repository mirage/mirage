(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1997 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)

(* $Id: marshal.mli 7164 2005-10-25 18:34:07Z doligez $ *)

(** Marshaling of data structures.

   This module provides functions to encode arbitrary data structures
   as sequences of bytes, which can then be written on a file or
   sent over a pipe or network connection.  The bytes can then
   be read back later, possibly in another process, and decoded back
   into a data structure. The format for the byte sequences
   is compatible across all machines for a given version of Objective Caml.

   Warning: marshaling is currently not type-safe. The type
   of marshaled data is not transmitted along the value of the data,
   making it impossible to check that the data read back possesses the
   type expected by the context. In particular, the result type of
   the [Marshal.from_*] functions is given as ['a], but this is
   misleading: the returned Caml value does not possess type ['a]
   for all ['a]; it has one, unique type which cannot be determined
   at compile-type.  The programmer should explicitly give the expected
   type of the returned value, using the following syntax:
   - [(Marshal.from_channel chan : type)].
   Anything can happen at run-time if the object in the file does not
   belong to the given type.

   The representation of marshaled values is not human-readable,
   and uses bytes that are not printable characters. Therefore,
   input and output channels used in conjunction with [Marshal.to_channel]
   and [Marshal.from_channel] must be opened in binary mode, using e.g.
   [open_out_bin] or [open_in_bin]; channels opened in text mode will
   cause unmarshaling errors on platforms where text channels behave
   differently than binary channels, e.g. Windows.
*)

type extern_flags =
    No_sharing                          (** Don't preserve sharing *)
  | Closures                            (** Send function closures *)
(** The flags to the [Marshal.to_*] functions below. *)

external to_string :
  'a -> extern_flags list -> string = "caml_output_value_to_string"
(** [Marshal.to_string v flags] returns a string containing
   the representation of [v] as a sequence of bytes.
   The [flags] argument has the same meaning as for
   {!Marshal.to_channel}. *)

val to_buffer : string -> int -> int -> 'a -> extern_flags list -> int
(** [Marshal.to_buffer buff ofs len v flags] marshals the value [v],
   storing its byte representation in the string [buff],
   starting at character number [ofs], and writing at most
   [len] characters.  It returns the number of characters
   actually written to the string. If the byte representation
   of [v] does not fit in [len] characters, the exception [Failure]
   is raised. *)

val from_string : string -> int -> 'a
(** [Marshal.from_string buff ofs] unmarshals a structured value
   like {!Marshal.from_channel} does, except that the byte
   representation is not read from a channel, but taken from
   the string [buff], starting at position [ofs]. *)

val header_size : int
(** The bytes representing a marshaled value are composed of
   a fixed-size header and a variable-sized data part,
   whose size can be determined from the header.
   {!Marshal.header_size} is the size, in characters, of the header.
   {!Marshal.data_size}[ buff ofs] is the size, in characters,
   of the data part, assuming a valid header is stored in
   [buff] starting at position [ofs].
   Finally, {!Marshal.total_size}[ buff ofs] is the total size,
   in characters, of the marshaled value.
   Both {!Marshal.data_size} and {!Marshal.total_size} raise [Failure]
   if [buff], [ofs] does not contain a valid header.

   To read the byte representation of a marshaled value into
   a string buffer, the program needs to read first
   {!Marshal.header_size} characters into the buffer,
   then determine the length of the remainder of the
   representation using {!Marshal.data_size},
   make sure the buffer is large enough to hold the remaining
   data, then read it, and finally call {!Marshal.from_string}
   to unmarshal the value. *)

val data_size : string -> int -> int
(** See {!Marshal.header_size}.*)

val total_size : string -> int -> int
(** See {!Marshal.header_size}.*)

(*
 * Copyright (c) 2009-2010 Thomas Gazagnaire <thomas@gazagnaire.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Dynamic types *)
type t =
	| Unit (** unit *)
	| Bool (** booleans *)
	| Float (** floating-point numbers *)
	| Char (** characters *)
	| String (** strings *)
	| Int of int option (** integer type of a given size (as 31-,32- or 64-bits); [Int None] is for bigints *)
	| List of t (** collection of stuff of the same type (stored as lists) *)
  | Array of t (** collection of stuff of the same type (stored as arrays) *)
	| Tuple of t list (** Cartesian product *)
	| Dict of [`R|`O] * (string * [ `RO | `RW ] * t) list (** record ['R] or object ['O] type; [`RW] stands for mutable fields *)
	| Sum of [`P|`N] * (string * t list) list (** polymorphic [`P] or normal [`N] variant type *)
	| Option of t (** option type *)
	| Rec of string * t (** recursive type *)
	| Var of string (** recursive fix-point *)
	| Arrow of t * t (** arrow type *)
	| Ext of string * t (** type variable *)


(** {2 Utility functions} *)

(** [is_mutable t] checks whether [t] contains a mutable field *)
val is_mutable : t -> bool

(** [free_vars t] returns all the free variables of type [t].
	If [t] is unfolded (as it should be when calling [type_of_t],
	this call should return an empty list. *)
val free_vars : t -> string list

(** [foreigns t] returns all the type variables appearing in [t]. *)
val foreigns : t -> string list

(** [unroll env t] replaces every type appearing in [t] by its type value defined in [env]. *)
val unroll : (string * t) list -> t -> t


(** {2 Sub-typing} *)

(** [is_subtype_of s t] checks whether [s] is a sub-type of [t]. Sub-typing relation is based on
	naming. Basically, [s] is a sub-type of [t] if (i) named attributes have either compatible types
	(ii) or some fields/methods defined in [t] do not appear in [s]. *)
val is_subtype_of : t -> t -> bool

(** [s <: t] is a short-cut for [is_subtype_of s t] *)
val ( <: ) : t -> t -> bool

(** Returns the more recent failing sub-type relation tested by [(<:)] or [is_subtype_of] *)
val string_of_last_type_error : unit -> string

(** {2 Pretty-printing} *)

(** [to_string t] pretty-prints the type [t] *)
val to_string : t -> string


(** Exception that may be raised by [!of_string] *)
exception Parse_error of string

(** [of_string str] returns the type [t] corresponding to the pretty-printed string [str]. Raises [!Parse_error]
	if is not a valid string *)
val of_string : string -> t

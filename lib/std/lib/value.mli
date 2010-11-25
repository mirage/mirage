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

(** Dynamic values *)
type t =
	| Unit (** unit *)
	| Int of int64 (** integers *)
	| Bool of bool (** booleans *)
	| Float of float (** floating-points numbers *)
	| String of string (** strings *)
	| Enum of t list (** collection of values of the same type (as lists or arrays) *)
	| Tuple of t list (** Cartesian product *)
	| Dict of (string * t) list (** records or objects *)
	| Sum of string * t list (** variants *)
	| Null (** empty value for option type *)
	| Value of t (** values for option type *)
	| Arrow of string (** arrows; value is marshaled using {!Marshal.to_string} *)
	| Rec of (string * int64) * t (** Recursive value (i.e. cyclic values) *)
	| Var of (string * int64) (** Fix-point variable for recursive value *)
	| Ext of (string * int64) * t (** values for type variables *)

(** {2 Utility functions} *)

(** [free_vars v] returns the free variables inside [v]. If [v] is obtained using [value_of_t] then this
	list should be empty *)
val free_vars : t -> (string * int64) list

(** Checks whether two values are equal (this looks for equivalence modulo eta-conversion on variable indices) *)
val equal : t -> t -> bool

(** [to_string v] pretty-prints the value [v] *)
val to_string : t -> string

(** Exception raised by {!of_string} *)
exception Parse_error of string

(** [of_string str] returns the value which had been pretty-printed to [str]. Raises {!Parse_error} if [str] has
	not a valid format. *)
val of_string : string -> t

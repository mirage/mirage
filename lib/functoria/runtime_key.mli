(*
 * Copyright (c) 2023 Thomas Gazagnaire <thomas@gazagnaire.org>
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

(** Runtime command-line arguments. *)

type 'a key
(** The type for runtime keys. Keys are used to retrieve the cross-stage values
    they are holding. *)

val create : ?name:string -> ?packages:Package.t list -> string -> 'a key

type t
(** The type for abstract {{!type:key} keys}. *)

val packages : t -> Package.t list

val v : 'a key -> t
(** [v k] is the [k] with its type hidden. *)

(** [Set] implements sets over [t] elements. *)
module Set : sig
  include Set.S with type elt = t

  val pp : t Fmt.t
  (** [pp] pretty-prints sets of keys. *)
end

(** {1 Code Serialization} *)

val call : 'a key Fmt.t
(** [call fmt k] outputs [name ()] to [fmt], where [n] is [k]'s {{!ocaml_name}
    OCaml name}. *)

val serialize : t Fmt.t
(** [serialize ctx ppf k] outputs the [Cmdliner] runes to parse command-line
    arguments represented by [k] at runtime. *)

(**/**)

val module_name : string
(** Name of the generated module containing the keys. *)

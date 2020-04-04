(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
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

(** Universal map of keys *)

type 'a key
(** The type for keys. *)

val new_key : string -> 'a key
(** [new_key n] is a new key with name [k]. *)

type t
(** The type for context maps. *)

val empty : t
(** [empty] is the empty context. *)

val add : 'a key -> 'a -> t -> t
(** [add k v t] is [t] augmented with the binding [(k, v)]. Any previous binding
    of [k] is removed. *)

val mem : 'a key -> t -> bool
(** [mem k t] is true iff [k] has been added to [t]. *)

val find : 'a key -> t -> 'a option
(** [find k t] is [v] is the binding [(k, v)] has been added to [t], otherwise
    it is [None]. *)

val merge : default:t -> t -> t
(** [merge ~default t] merges [t] on top of [default]. If a key appears in both
    [default] and [t], the value present in [t] is kept. *)

val dump : t Fmt.t
(** [dump] dumps the state of [t]. *)

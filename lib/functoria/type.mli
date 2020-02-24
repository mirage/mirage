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

(** Representation of module signatures. *)

(** The type for values representing module types. *)
type 'a t = Type : 'a -> 'a t | Function : 'a t * 'b t -> ('a -> 'b) t

val v : 'a -> 'a t
(** [type t] is a value representing the module type [t]. *)

val ( @-> ) : 'a t -> 'b t -> ('a -> 'b) t
(** [x @-> y] is the functor type from the module signature [x] to the module
    signature [y]. This corresponds to prepending a parameter to the list of
    functor parameters. For example:

    {[ kv_ro @-> ip @-> kv_ro ]}

    This describes a functor type that accepts two arguments -- a [kv_ro] and an
    [ip] device -- and returns a [kv_ro]. *)

val is_functor : _ t -> bool
(** [is_functor t] is true if [t] has type [(a -> b) t]. *)

val pp : 'a t Fmt.t
(** [pp] is the pretty printer for module types. *)

(** {1 Useful module types} *)

type job
(** Type for job values. *)

val job : job t
(** [job] is the signature for user's application main module. *)

type argv
(** The type for command-line arguments, similar to the usual [Sys.argv]. *)

val argv : argv t
(** [argv] is a value representing {!argv} module types. *)

type info
(** The type for application about the application being built. *)

val info : info t
(** [info] is a value representing {!info} module types. *)

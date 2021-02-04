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

(** Typed identifiers and equality witnesses *)

type 'a t
(** A typed unique identifiers *)

val gen : unit -> 'a t
(** [gen ()] creates a new unique identifier. *)

val equal : 'r t -> 's t -> bool
(** [equal tid1 tid2] tests if [tid1] and [tid2] are equal. *)

val id : 'a t -> int
(** [id tid] returns a integer that uniquely identify [tid]. *)

val pp : Format.formatter -> 'a t -> unit
(** [pp ppf tid] prints [id tif]. *)

(** A annotated boolean that also witness the equality between two types. *)
type (_, _) witness = Eq : ('a, 'a) witness | NotEq : ('a, 'b) witness

val witness : 'r t -> 's t -> ('r, 's) witness
(** [witness tid1 tid2] is equivalent to [equal tid1 tid2], but exposes the
    equality between their types. *)

val to_bool : ('a, 'b) witness -> bool
(** [to_bool w] converts the witness into a boolean. *)

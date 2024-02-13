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

type t

val v : ?bin:(Fpath.t * Fpath.t) list -> ?etc:Fpath.t list -> unit -> t
(** [v ~bin:[(src,dst),...] ~etc ()] is the installation of [src] as [dst] as
    binary files, and [etc] as configuration/artifact. *)

val union : t -> t -> t
(** [union a b] merge to sets of installation rules. *)

val empty : t
(** [empty] is the installation of nothing. *)

val pp : t Fmt.t
(** Print the .install rules to install [t] *)

val pp_opam : ?subdir:Fpath.t -> unit -> t Fmt.t
(** Print the opam rules to install [t]. If [~subdir] is provided, this will be
    used as prefix (i.e. if your unikernel is in the "tutorial/hello/"
    subdirectory (which is passed as [~subdir], the install instructions will
    use [cp tutorial/hello/dist/hello.hvt %{bin}%/hello.hvt]). *)

val dune :
  context_name_for_bin:string -> context_name_for_etc:string -> t -> Dune.t
(** [dune ~context_name_for_bin ~context_name_for_etc ()] is the dune rules to
    promote installed files back in the source tree. A context-name is required
    for [bin] and [etc] artifacts. The first one should be the cross-compiler
    context and the second one should be the host's compiler context. *)

val dump : t Fmt.t
(** Dump installation rules. *)

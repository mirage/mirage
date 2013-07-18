(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
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

(** Configuration library *)

(** Usage modes *)
type mode = [
  |`unix of [`direct | `socket ]
  |`xen
]

(** [configure ~mode ~no_install conf_file] configure a project. If
    [conf_file] is [None], then look for a `.conf` file in the current
    directory. *)
val configure: mode:mode -> no_install:bool -> string option -> unit

(** [build ~mode ~no_install conf_file] builds a project. If
    [conf_file] is [None], then look for a `.conf` file in the current
    directory. *)
val build: mode:mode -> string option -> unit

(** [run ~mode conf_file] runs a project. If [conf_file] is [None],
    then look for a `.conf` file in the current directory. *)
val run: mode:mode -> string option -> unit

(** [clean file] clean a project. If [confi_file] is [None], then look
    for a `.conf` file in the current directory. *)
val clean: string option -> unit

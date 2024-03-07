(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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

(** Command-line arguments for the Mirage configuration tool. *)

include module type of Functoria.Key

type mode_unix = [ `Unix | `MacOSX ]
type mode_xen = [ `Xen | `Qubes ]
type mode_solo5 = [ `Hvt | `Spt | `Virtio | `Muen | `Genode ]
type mode = [ mode_unix | mode_xen | mode_solo5 ]

(** {2 Mirage keys} *)

val target : mode key
(** [-t TARGET]: Key setting the configuration mode for the current project. Is
    one of ["unix"], ["macosx"], ["xen"], ["qubes"], ["virtio"], ["hvt"],
    ["muen"], ["genode"] or ["spt"]. *)

val pp_target : mode Fmt.t
(** Pretty printer for the mode. *)

val is_unix : bool value
(** Is true iff the {!target} key is a UNIXish system (["unix" or "macosx"]). *)

val is_solo5 : bool value
(** Is true iff the {!target} key is a Solo5-based target. *)

val is_xen : bool value
(** Is true iff the {!target} key is a Xen-based system (["xen" or "qubes"]). *)

(** {2 Generic keys}

    Some keys have a [group] optional argument. This group argument allows to
    give several keys a prefix.

    For example, if we have two [ip] stacks, one external and one internal, We
    can use the [group] option to name them [in] and [out]. This way, the
    available keys will be [--in-ip] and [--out-ip].

    If a key has another, non-optional argument. It is the default value.

    Keys are always named the same as their command line option. *)

(** {3 File system keys} *)

val kv_ro : ?group:string -> unit -> [ `Crunch | `Direct ] key
(** The type of key value store. Is one of ["crunch"], or ["direct"]. *)

val block : ?group:string -> unit -> [ `XenstoreId | `BlockFile | `Ramdisk ] key
(** {3 Block device keys} *)

(** {3 Stack keys} *)

val dhcp : ?group:string -> unit -> bool key
(** Enable dhcp. Is either [true] or [false]. *)

val net : ?group:string -> unit -> [ `Direct | `Socket ] option key
(** The type of stack. Is either ["direct"] or ["socket"]. *)

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

(** Creation of CLI tools to assemble functors. *)

open DSL

module type S = sig
  val name : string
  (** Name of the tool. *)

  val version : string
  (** Version of the tool. *)

  val packages : package list
  (** The packages to load when compiling the configuration file. *)

  val create : job impl list -> job impl
end

module Make (P : S) : sig
  val run : unit -> unit
  (** Run the configuration builder. This should be called exactly once to run
      the configuration builder: command-line arguments will be parsed, and some
      code will be generated and compiled. *)

  val run_with_argv :
    ?help_ppf:Format.formatter ->
    ?err_ppf:Format.formatter ->
    string array ->
    unit
  (** [run_with_argv a] is the same as {!run} but parses [a] instead of the
      process command line arguments. It also allows to set the error and help
      channels using [help_ppf] and [err_ppf]. *)
end

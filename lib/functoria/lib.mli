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

(** Application builder. API for building libraries to link with [config.ml] *)

(** {1 Builders} *)

(** [S] is the signature that application builders have to provide. *)
module type S = sig
  open DSL

  val prelude : Info.t -> string
  (** Prelude printed at the beginning of [main.ml].

      It should put in scope:

      - a [run] function of type ['a t -> 'a]
      - a [return] function of type ['a -> 'a t]
      - a [>>=] operator of type ['a t -> ('a -> 'b t) -> 'b t] *)

  val packages : Package.t list
  (** The packages to load when compiling the configuration file. *)

  val name : string
  (** Name of the custom DSL. *)

  val version : string
  (** Version of the custom DSL. *)

  val create : job impl list -> job impl
  (** [create jobs] is the top-level job in the custom DSL which will execute
      the given list of [job]. *)

  val name_of_target : Info.t -> string
  (** [name_of_target i] is the name used to build the project with the build
      info [i]. For simple projects it can be [Info.name]. For more complex
      projects (like [mirage]), the name is suffixed by the value of the target
      key defined in [i]. *)

  val dune_project : Dune.stanza list
  val dune_workspace : (?build_dir:Fpath.t -> info -> Dune.t) option
  val context_name : Info.t -> string
end

module Make (_ : S) : sig
  open DSL

  (** Configuration builder: stage 1 *)

  val register :
    ?init:job impl list ->
    ?src:[ `Auto | `None | `Some of string ] ->
    string ->
    job impl list ->
    unit
  (** [register name jobs] registers the application named by [name] which will
      execute the given [jobs]. Same optional arguments as {!module-DSL.main}.

      [init] is the list of job to execute before anything else (such as
      command-line argument parsing, log reporter setup, etc.). The jobs are
      always executed in the sequence specified by the caller. *)
end

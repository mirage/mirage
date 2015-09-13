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

(** A configuration engine. For internal use. *)
module type CONFIG = sig
  type info

  val name : string
  (** Name of the project. *)

  val version : string
  (** Version of the project. *)

  (** {2 Configuration} *)

  type t
  (** A configuration. *)

  val base_keys : unit Cmdliner.Term.t
  (** Base keys provided by the specialized DSL. *)

  val load: string option -> (t, string) Rresult.result
  (** Read a config file. If no name is given, search for use
      [config.ml]. *)

  val switching_keys : t -> unit Cmdliner.Term.t

  val eval : t -> <
      build : info -> (unit, string) Rresult.result;
      clean : info -> (unit, string) Rresult.result;
      configure :
        info ->
        no_opam:bool ->
        no_depext:bool ->
        no_opam_version:bool ->
        (unit, string) Rresult.result;
      info : info Cmdliner.Term.t;
      describe :
        dotcmd:string -> dot:bool -> eval:bool ->
        string option -> unit;
    >

end

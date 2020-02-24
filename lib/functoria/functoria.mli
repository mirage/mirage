(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
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

(** The Functoria DSL.

    The Functoria DSL allows users to describe how to create portable and
    flexible applications. It allows to pass application parameters easily using
    command-line arguments either at configure-time or at runtime.

    Users of the Functoria DSL composes their application by defining a list of
    {{!foreign} module} implementations, specify the command-line {!keys} that
    are required and {{!combinators} combine} all of them together using
    {{:http://dx.doi.org/10.1017/S0956796807006326} applicative} operators.

    The DSL expression is then compiled into an {{!app} application builder},
    which will, once evaluated, produced the final portable and flexible
    application. *)

module type DSL = module type of Functoria_DSL

include DSL

(** The signature for run-time and configure-time command-line keys. *)
module type KEY =
  module type of Functoria_key
    with type 'a Arg.converter = 'a Functoria_key.Arg.converter
     and type 'a Arg.t = 'a Functoria_key.Arg.t
     and type Arg.info = Functoria_key.Arg.info
     and type 'a value = 'a Functoria_key.value
     and type 'a key = 'a Functoria_key.key
     and type t = Functoria_key.t
     and type Set.t = Functoria_key.Set.t
     and type 'a Alias.t = 'a Functoria_key.Alias.t
     and type context = Functoria_key.context

module Package = Functoria_package
module Info = Functoria_info
module Install = Functoria_install
module Device = Functoria_device

(** {1 Useful module implementations} *)

val job : job typ
(** [job] is the signature for user's application main module. *)

val noop : job impl
(** [noop] is an implementation of {!Functoria.job} that holds no state, does
    nothing and has no dependency. *)

type argv = Functoria_argv.t
(** The type for command-line arguments, similar to the usual [Sys.argv]. *)

val argv : argv typ
(** [argv] is a value representing {!argv} module types. *)

val sys_argv : argv impl
(** [sys_argv] is a device providing command-line arguments by using
    {!Sys.argv}. *)

val keys : argv impl -> job impl
(** [keys a] is an implementation of {!Functoria.job} that holds the parsed
    command-line arguments. *)

val info : info typ
(** [info] is a value representing {!info} module types. *)

val app_info :
  ?opam_deps:(string * string) list -> ?gen_modname:string -> unit -> info impl
(** [app_info] is the module implementation whose state contains all the
    information available at configure-time. The value is stored into a
    generated module name [gen_modname]: if not set, it is [Info_gen]. *)

module Type = Functoria_type
module Impl = Functoria_impl
module Key = Functoria_key
module Codegen = Functoria_codegen
module Opam = Functoria_opam
module App = Functoria_app
module Graph = Functoria_graph
module Engine = Functoria_engine
module DSL = Functoria_DSL
module Cli = Functoria_cli

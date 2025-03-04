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

(** {1 The Functoria DSL} *)

(** Functoria is a DSL to describe a set of modules and functors, their types
    and how to apply them in order to produce a complete application.

    The main use case is mirage. See the [Mirage] documentation for details.

    Functoria is a DSL to write configuration files for functor-heavy
    applications. Such configuration files (imaginatively called [config.ml])
    usually contains three parts: one for defining toplevel modules, one for
    defining configuration kyes and one for defining applications using these
    modules and keys.

    {2 Defining toplevel modules}

    To define toplevel modules, use the {!main} function. Among its various
    arguments, it takes the module name and its signature. The type is assembled
    with the {!Type} combinators, like the [@->] operator, which represents a
    functor arrow.

    {[
      let main = main "Unikernel.Main" (m @-> job)
    ]}

    This declares that the functor [Unikernel.Main] takes a module of type [m]
    and returns a module of type {!module-DSL.job}. [job] has a specific meaning
    for functoria: it is a module which defines at least a function [start],
    which should have one argument per functor argument and should return
    [unit].

    It is up to the user to ensure that the declaration matches the
    implementation, or be rewarded by a compiler error later on. If the
    declaration is correct, everything that follows will be.

    {2 Defining configuration keys}

    A configuration key is composed of:

    - {i name} : The name of the value in the program.
    - {i description} : How it should be displayed/serialized.
    - {i stage} : Is the key available only at runtime, at configure time or
      both?
    - {i documentation} : It is not optional so you should really write it.

    Consider a multilingual application: we want to pass the default language as
    a parameter. We will use a simple string, so we can use the predefined
    description {!Key.Arg.string}. We want to be able to define it both at
    configure and run time, so we use the stage [Both]. This gives us the
    following code:

    {[
      let lang_key =
        let doc =
          Key.Arg.info ~doc:"The default language for the application."
            [ "l"; "lang" ]
        in
        Key.create "language" @@ Key.Arg.(opt ~stage:`Both string "en" doc)
    ]}

    Here, we defined both a long option ["--lang"] and a short one ["-l"] (the
    format is similar to the one used by
    {{:http://erratique.ch/software/cmdliner} Cmdliner}. In the application
    code, the value is retrieved with [Key_gen.language ()].

    The option is also documented in the ["--help"] option for both the
    [configure] subcommand (at configure time) and [./app.exe] (at startup
    time).

    {v
      -l VAL, --lang=VAL (absent=en) The default language for the application.
    v}

    {2 Defining applications}

    To register a new application, use [register]:

    {[
      let () = register "app" [ main $ impl ]
    ]}

    This function (which should only be called once) takes as argument the name
    of the application and a list of jobs. The jobs are defined using the
    {!Impl} DSL; for instance the operator [$] is used to apply the functor
    [main] (aka [Unikernel.Main]) to the default console.

    Once an application is registered, it can be configured and built using
    command-line arguments.

    Configuration keys we can use be used to switch implementation at configure
    time. This is done by using the {!Key} DSL, for instance to check whether
    [lang_key] is instanciated with a given string:

    {[
      let lang_is "s" = Key.(pure (( = ) s) $ value lang_key)
    ]}

    Then by using the {!if_impl} combinator to choose between two
    implementations depending on the value of the key:

    {[
      let impl = if_impl (is "fi") finnish_impl not_finnish_implementation
    ]} *)

module type DSL = module type of DSL

include DSL
module Package = Package
module Info = Info
module Install = Install
module Device = Device

(** {1 Useful module implementations} *)

val job : job typ
(** [job] is the signature for user's application main module. *)

val noop : job impl
(** [noop] is an implementation of {!type-job} that holds no state, does nothing
    and has no dependency. *)

type argv = Argv.t
(** The type for command-line arguments, similar to the usual [Sys.argv]. *)

val argv : argv typ
(** [argv] is a value representing {!type-argv} module types. *)

val sys_argv : argv impl
(** [sys_argv] is a device providing command-line arguments by using [Sys.argv].
*)

val runtime_args :
  ?runtime_package:package -> ?runtime_modname:string -> argv impl -> job impl
(** [runtime_args a] is an implementation of {!type-job} that holds the parsed
    command-line arguments. By default [runtime_package] is
    ["mirage-runtime.functoria"] and [runtime_modname] is ["Functoria_runtime"].
*)

module Type = Type
module Impl = Impl
module Context = Context
module Key = Key
module Runtime_arg = Runtime_arg
module Opam = Opam
module Lib = Lib
module Tool = Tool
module Engine = Engine
module DSL = DSL
module Cli = Cli
module Action = Action
module Dune = Dune

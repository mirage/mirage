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

module Context = Context
module Key = Key
module Runtime_arg = Runtime_arg
module Package = Package
module Info = Info
module Type = Type
module Impl = Impl
module Device = Device
module Install = Install
module Opam = Opam
module Lib = Lib
module Tool = Tool
module Engine = Engine
module DSL = DSL
module Cli = Cli
module Action = Action
module Dune = Dune

module type DSL = module type of DSL

module type KEY =
  module type of Key
    with type 'a Arg.t = 'a Key.Arg.t
     and type 'a value = 'a Key.value
     and type 'a key = 'a Key.key
     and type t = Key.t
     and type Set.t = Key.Set.t

(** Devices *)

include DSL

let job = Job.t
let noop = Job.noop
let runtime_args = Job.runtime_args

type argv = Argv.t

let sys_argv = Argv.sys_argv
let argv = Argv.argv

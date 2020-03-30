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

module Key = Key
module Package = Package
module Info = Info
module Type = Type
module Impl = Impl
module Device = Device
module Install = Install
module Opam = Opam
module Lib = Lib
module Tool = Tool
module Graph = Device_graph
module Engine = Engine
module DSL = DSL
module Cli = Cli
module Action = Action

module type DSL = module type of DSL

module type KEY =
  module type of Key
    with type 'a Arg.converter = 'a Key.Arg.converter
     and type 'a Arg.t = 'a Key.Arg.t
     and type Arg.info = Key.Arg.info
     and type 'a value = 'a Key.value
     and type 'a key = 'a Key.key
     and type t = Key.t
     and type Set.t = Key.Set.t
     and type 'a Alias.t = 'a Key.Alias.t
     and type context = Key.context

(** Devices *)

include DSL

let job = Job.t

let noop = Job.noop

let info = Info.t

let keys ?runtime_package ?runtime_modname x =
  Job.keys ?runtime_package ?runtime_modname x

type argv = Argv.t

let sys_argv = Argv.sys_argv

let argv = Argv.argv

let app_info =
  let v ~packages ~connect ~clean ~build s t =
    Impl.v ~packages ~connect ~clean ~build s t
  in
  Info.app_info v

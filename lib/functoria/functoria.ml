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

module Key = Functoria_key
module Package = Functoria_package
module Info = Functoria_info
module Type = Functoria_type
module Impl = Functoria_impl
module Device = Functoria_device
module Install = Functoria_install
module Codegen = Functoria_codegen
module Opam = Functoria_opam
module App = Functoria_app
module Graph = Functoria_graph
module Engine = Functoria_engine
module DSL = Functoria_DSL
module Cli = Functoria_cli

module type DSL = module type of Functoria_DSL

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

(** Devices *)

include Functoria_DSL

let job = Functoria_job.t

let noop = Functoria_job.noop

let info = Functoria_info.t

let keys = Functoria_job.keys

type argv = Functoria_argv.t

let sys_argv = Functoria_argv.sys_argv

let argv = Functoria_argv.argv

let app_info =
  let v ~packages ~connect ~clean ~build s t =
    Impl.v ~packages ~connect ~clean ~build s t
  in
  Functoria_info.app_info v

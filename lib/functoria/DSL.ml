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

type 'a key = 'a Key.key
type 'a runtime_arg = 'a Runtime_arg.arg
type 'a value = 'a Key.value
type abstract_key = Key.t
type package = Package.t
type scope = Package.scope
type 'a typ = 'a Type.t
type 'a impl = 'a Impl.t
type abstract_impl = Impl.abstract
type 'a device = ('a, Impl.abstract) Device.t
type context = Context.t
type job = Job.t
type info = Info.t
type 'a code = 'a Device.code

let code = Device.code
let package = Package.v
let ( @-> ) = Type.( @-> )
let typ = Type.v
let ( $ ) = Impl.( $ )
let of_device = Impl.of_device
let key = Key.v
let dep = Impl.abstract
let if_impl = Impl.if_
let match_impl = Impl.match_

let impl ?packages ?packages_v ?local_libs ?install ?install_v ?keys
    ?runtime_args ?extra_deps ?connect ?dune ?configure ?files module_name
    module_type =
  of_device
  @@ Device.v ?packages ?packages_v ?local_libs ?install ?install_v ?keys
       ?runtime_args ?extra_deps ?connect ?dune ?configure ?files module_name
       module_type

let main ?pos ?packages ?packages_v ?local_libs ?runtime_args ?deps module_name
    ty =
  let connect _ = Device.start ?pos in
  let extra_deps =
    if Type.is_functor ty then deps
    else
      match deps with
      | None | Some [] ->
          print_endline
            "adding unit argument to 'start ()' (to delay execution)";
          Some [ dep Job.noop ]
      | _ -> deps
  in
  impl ?packages ?packages_v ?local_libs ?runtime_args ?extra_deps ~connect
    module_name ty

let runtime_arg ~pos ?packages str =
  Runtime_arg.v (Runtime_arg.create ~pos ?packages str)

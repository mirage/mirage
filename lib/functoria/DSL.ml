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

type 'a value = 'a Key.value

type package = Package.t

type 'a typ = 'a Type.t

type 'a impl = 'a Impl.t

type 'a device = ('a, Impl.abstract) Device.t

let package = Package.v

let ( @-> ) = Type.( @-> )

let typ = Type.v

let ( $ ) = Impl.( $ )

let of_device = Impl.of_device

let abstract = Impl.abstract

let if_impl = Impl.if_

let match_impl = Impl.match_

let impl ?packages ?packages_v ?keys ?extra_deps ?connect ?dune ?files ?build
    module_name module_type =
  of_device
  @@ Device.v ?packages ?packages_v ?keys ?extra_deps ?connect ?dune ?files
       ?build module_name module_type

let main ?packages ?packages_v ?keys ?extra_deps module_name ty =
  let connect _ = Device.start in
  impl ?packages ?packages_v ?keys ?extra_deps ~connect module_name ty

let foreign ?packages ?packages_v ?keys ?deps module_name ty =
  main ?packages ?packages_v ?keys ?extra_deps:deps module_name ty

type context = Key.context

type abstract_key = Key.t

type job = Job.t

type info = Info.t

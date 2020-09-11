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

type t = {
  name : string;
  depends : Package.t list;
  build : string list;
  pins : (string * string) list;
}

let v ?(build = []) ?(depends = []) ?(pins = []) name =
  { name; depends; build; pins }

let pp_packages ppf packages =
  Fmt.pf ppf "\n  %a\n"
    Fmt.(list ~sep:(unit "\n  ") (Package.pp ~surround:"\""))
    packages

let pp_pins ppf = function
  | [] -> ()
  | pins ->
      let pp_pin ppf (package, url) =
        Fmt.pf ppf "[\"%s.dev\" %S]" package url
      in
      Fmt.pf ppf "@.pin-depends: [ @[<hv>%a@]@ ]@."
        Fmt.(list ~sep:(unit "@ ") pp_pin)
        pins

let pp ppf t =
  let pp_build = Fmt.list ~sep:(Fmt.unit " ") (Fmt.fmt "%S") in
  Fmt.pf ppf
    {|opam-version: "2.0"
name: "%s"
maintainer: "dummy"
authors: "dummy"
homepage: "dummy"
bug-reports: "dummy"
synopsis: "This is a dummy"

build: [%a]

depends: [%a]
%a|}
    t.name pp_build t.build pp_packages t.depends pp_pins t.pins

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

open Action.Syntax

let find_git () =
  let is_git p = Action.is_dir Fpath.(p / ".git") in
  let app_opt p d = match p with None -> d | Some p -> Fpath.(d // p) in
  let rec find p path =
    if Fpath.is_root p then Action.ok None
    else
      let* has_git = is_git p in
      if has_git then Action.ok (Some path)
      else find (Fpath.parent p) (Some (app_opt path (Fpath.base p)))
  in
  let* cwd = Action.pwd () in
  let* cwd = find cwd None in
  match cwd with
  | None -> Action.ok None
  | Some subdir ->
      let git_branch =
        Bos.Cmd.(v "git" % "rev-parse" % "--abbrev-ref" % "HEAD")
      in
      let* branch = Action.(run_cmd_out ~err:`Null git_branch) in
      let git_remote = Bos.Cmd.(v "git" % "remote" % "get-url" % "origin") in
      let+ git_url = Action.(run_cmd_out ~err:`Null git_remote) in
      Some (subdir, branch, git_url)

let guess_src () =
  let git_info =
    match Action.run @@ find_git () with
    | Error _ | Ok None -> None
    | Ok (Some (_, branch, git_url)) -> Some (branch, git_url)
  in
  match git_info with
  | None -> None
  | Some (branch, origin) ->
      (* TODO is there a library for git urls anywhere? *)
      let public =
        match Astring.String.cut ~sep:"github.com:" origin with
        | Some (_, post) -> "git+https://github.com/" ^ post
        | _ -> origin
      in
      Some (Fmt.str "%s#%s" public branch)

type target = [ `Switch | `Monorepo ]

type t = {
  name : string;
  depends : Package.t list;
  build : string list;
  install : Install.t;
  pins : (string * string) list;
  src : string option;
  target : target;
}

let v ?(build = []) ?(install = Install.empty) ?(depends = []) ?(pins = [])
    ~target ~src name =
  let src =
    match src with `Auto -> guess_src () | `None -> None | `Some d -> Some d
  in
  { name; depends; build; install; pins; target; src }

let pp_packages ppf packages =
  Fmt.pf ppf "\n  %a\n"
    Fmt.(list ~sep:(any "\n  ") (Package.pp ~surround:"\""))
    packages

let pp_pins ppf = function
  | [] -> ()
  | pins ->
      let pp_pin ppf (package, url) =
        Fmt.pf ppf "[\"%s.dev\" %S]" package url
      in
      Fmt.pf ppf "@.pin-depends: [ @[<hv>%a@]@ ]@."
        Fmt.(list ~sep:(any "@ ") pp_pin)
        pins

let pp_src ppf = function
  | None -> ()
  | Some src -> Fmt.pf ppf {|@.url { src: %S }|} src

let pp ppf t =
  let pp_build ppf =
    Fmt.pf ppf "\n%a\n" (Fmt.list ~sep:(Fmt.any "\n") (Fmt.fmt "  [ %s ]"))
  in
  match t.target with
  | `Switch ->
      Fmt.pf ppf
        {|opam-version: "2.0"
name: "%s"
maintainer: "dummy"
authors: "dummy"
homepage: "dummy"
bug-reports: "dummy"
dev-repo: "git://dummy"
synopsis: "Unikernel %s - switch dependencies"
description: """
It assumes that local dependencies are already
fetched.
"""

build: [%a]

install: [%a]

depends: [%a]
%a%a|}
        t.name t.name pp_build t.build Install.pp_opam t.install pp_packages
        t.depends pp_src t.src pp_pins t.pins
  | `Monorepo ->
      Fmt.pf ppf
        {|opam-version: "2.0"
name: "%s"
maintainer: "dummy"
authors: "dummy"
homepage: "dummy"
bug-reports: "dummy"
dev-repo: "git://dummy"
synopsis: "Unikernel %s - monorepo dependencies"

depends: [%a]
%a
|}
        t.name t.name pp_packages t.depends pp_pins t.pins

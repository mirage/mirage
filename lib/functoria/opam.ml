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

module Endpoint = struct
  type t = {
    scheme : [ `SSH of string | `Git | `HTTP | `HTTPS | `Scheme of string ];
    port : int option;
    path : string;
    hostname : string;
  }

  let of_string str =
    let open Rresult in
    let parse_ssh str =
      let len = String.length str in
      Emile.of_string_raw ~off:0 ~len str
      |> R.reword_error (R.msgf "%a" Emile.pp_error)
      >>= fun (consumed, m) ->
      match
        Astring.String.cut ~sep:":" (String.sub str consumed (len - consumed))
      with
      | Some ("", path) ->
          let local =
            List.map
              (function `Atom x -> x | `String x -> Fmt.str "%S" x)
              m.Emile.local
          in
          let user = String.concat "." local in
          let hostname =
            match fst m.Emile.domain with
            | `Domain vs -> String.concat "." vs
            | `Literal v -> v
            | `Addr (Emile.IPv4 v) -> Ipaddr.V4.to_string v
            | `Addr (Emile.IPv6 v) -> Ipaddr.V6.to_string v
            | `Addr (Emile.Ext (k, v)) -> Fmt.str "%s:%s" k v
          in
          R.ok { scheme = `SSH user; path; port = None; hostname }
      | _ -> R.error_msg "Invalid SSH pattern"
    in
    let parse_uri str =
      let uri = Uri.of_string str in
      let path = Uri.path uri in
      match (Uri.scheme uri, Uri.host uri, Uri.port uri) with
      | Some "git", Some hostname, port ->
          R.ok { scheme = `Git; path; port; hostname }
      | Some "http", Some hostname, port ->
          R.ok { scheme = `HTTP; path; port; hostname }
      | Some "https", Some hostname, port ->
          R.ok { scheme = `HTTPS; path; port; hostname }
      | Some scheme, Some hostname, port ->
          R.ok { scheme = `Scheme scheme; path; port; hostname }
      | _ -> R.error_msgf "Invalid uri: %a" Uri.pp uri
    in
    match (parse_ssh str, parse_uri str) with
    | Ok v, _ -> Ok v
    | _, Ok v -> Ok v
    | Error _, Error _ -> R.error_msgf "Invalid endpoint: %s" str
end

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
        match Endpoint.of_string origin with
        | Ok
            { Endpoint.scheme = `Scheme scheme; port = None; path; hostname; _ }
          ->
            Fmt.str "%s://%s/%s" scheme hostname path
        | Ok
            {
              Endpoint.scheme = `Scheme scheme;
              port = Some port;
              path;
              hostname;
              _;
            } ->
            Fmt.str "%s://%s:%d/%s" scheme hostname port path
        | Ok { Endpoint.port = None; path; hostname; _ } ->
            Fmt.str "git+https://%s/%s" hostname path
        | Ok { Endpoint.port = Some port; path; hostname; _ } ->
            Fmt.str "git+https://%s:%d/%s" hostname port path
        | _ -> "git+https://invalid/endpoint"
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
      let pp_pin ppf (package, url) = Fmt.pf ppf "[\"%s\" %S]" package url in
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

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

type t = {
  depext : bool;
  global_vars : (string * string) list;
  repositories : (string * string) list;
}

let default_repostories =
  [ ("default", "git+https://github.com/ocaml/opam-repository.git") ]

let v ?(extra_repo = []) ~depext () =
  let+ global_vars =
    let+ opam_version = Action.run_cmd_out Bos.Cmd.(v "opam" % "--version") in
    [ ("opam-version", opam_version); ("monorepo", "true") ]
  in
  { depext; repositories = extra_repo @ default_repostories; global_vars }

let depext_rules =
  {|
depext-lockfile: install-switch
	echo " ↳ install external dependencies for monorepo"
	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo depext -y -l $(LOCK_FILE)
|}

let pp_extra_rules ppf t =
  let rules, targets =
    match t.depext with
    | true -> ([ depext_rules ], [ "depext-lockfile" ])
    | false -> ([], [])
  in
  match rules with
  | [] -> ()
  | _ ->
      Fmt.pf ppf " %a\n\n"
        (Fmt.list ~sep:(fun ppf () -> Fmt.pf ppf " ") Fmt.string)
        targets;
      Fmt.pf ppf "%a"
        (Fmt.list ~sep:(fun ppf () -> Fmt.pf ppf "\n\n") Fmt.string)
        rules

let pp_repositories ppf rs =
  List.map snd rs |> String.concat "," |> Fmt.pf ppf "[%s]"

let pp_global_vars ppf vs =
  Fmt.pf ppf "[%s]"
    (String.concat "," (List.map (fun (k, v) -> Fmt.str "[%s,%s]" k v) vs))

let pp_depext_lockfile ppf = function
  | true -> Fmt.string ppf "\n\t@$(MAKE) -s depext-lockfile"
  | false -> ()

let pp_no_depext ppf = function
  | true -> ()
  | false -> Fmt.string ppf " --no-depexts"

let pp ppf t =
  Fmt.pf ppf
    {|-include Makefile.user
OPAM = opam
OPAMS = $(shell find . -type f -name '*.opam' | grep -vE '(_build|_opam|duniverse)/')
PROJECT = pkg
LOCK_FILE = $(PROJECT).opam.locked

REPOSITORIES = "%a"
GLOBAL_VARS  = "%a"

all:: depends build

.PHONY: all lock install-switch pull clean depend depends build%a

$(LOCK_FILE): $(OPAMS)
	@@echo " ↳ generate lockfile for monorepo dependencies"
	@@$(OPAM) monorepo lock --require-cross-compile --build-only -l $@@ --opam-repositories $(REPOSITORIES) -vv --recurse-opam --add-global-opam-vars $(GLOBAL_VARS) --ocaml-version $(shell ocamlc --version)

lock:: $(LOCK_FILE)
	@@

pull:: $(LOCK_FILE)
	@@echo " ↳ fetch monorepo dependencies in the duniverse folder"
	@@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $<

install-switch:: $(OPAMS)
	@@echo " ↳ opam install switch dependencies"
	@@$(OPAM) install $< --deps-only --yes%a%a

depends depend:: lock install-switch depext-lockfile pull

build::
	dune build --profile release --root .

clean::
	mirage clean
|}
    pp_repositories t.repositories pp_global_vars t.global_vars pp_extra_rules t
    pp_no_depext t.depext pp_depext_lockfile t.depext

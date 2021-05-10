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
  depext : bool;
  build_dir : Fpath.t;
  name : string;
  unikernel_name : string;
  extra_repo : string option;
}

let v ?extra_repo ~build_dir ~name ~depext unikernel_name =
  { depext; build_dir; name; unikernel_name; extra_repo }

let depext_rules =
  {|depext:
	echo " ↳ opam depexts"
ifneq (,$(findstring 2.0.,$(shell opam --version)))
	$(OPAM) pin add -k path --no-action --yes $(UNIKERNEL_NAME)-install $(MIRAGE_DIR)
	$(OPAM) depext --yes --update $(UNIKERNEL_NAME)-install
	$(OPAM) pin remove --no-action $(UNIKERNEL_NAME)-install
else
	opam install --cli 2.1 --depext-only $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-install.opam
endif

depext-lockfile:
	echo " ↳ lockfile depexts"
ifneq (,$(findstring 2.0.,$(shell opam --version)))
	$(OPAM) pin add -k path --no-action --yes $(UNIKERNEL_NAME) $(MIRAGE_DIR) --locked --ignore-pin-depends
	$(OPAM) depext --yes --update $(UNIKERNEL_NAME)
	$(OPAM) pin remove --no-action $(UNIKERNEL_NAME)
else
	opam install --cli 2.1 --ignore-pin-depends --depext-only --locked $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
endif

|}

let opam_repo_add_rule repo =
  Fmt.str
    {|repo-add:
	echo -e "\e[2musing overlay repository mirage-tmp: %s \e[0m"
	$(OPAM) repo add mirage-tmp %s ||\
	$(OPAM) repo set-url mirage-tmp %s|}
    repo repo repo

let opam_repo_remove_rule =
  Fmt.str
    {|repo-rm:
	echo -e "\e[2mremoving overlay repository mirage-tmp\e[0m"
	$(OPAM) repo remove mirage-tmp|}

let pp_extra_rules ppf t =
  let rules, targets =
    match t.depext with
    | true -> ([ depext_rules ], [ "depext"; "depext-lockfile" ])
    | false -> ([], [])
  in
  let rules, targets =
    match t.extra_repo with
    | Some repo ->
        ( opam_repo_add_rule repo :: opam_repo_remove_rule :: rules,
          "repo-add" :: "repo-rm" :: targets )
    | None -> (rules, targets)
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

let pp ppf t =
  let mirage_dir = Fpath.(t.build_dir / t.name) in
  let pp_depext ppf = function
    | true -> Fmt.pf ppf "\n\t@@$(MAKE) -s depext"
    | false -> ()
  and pp_depext_lockfile ppf = function
    | true -> Fmt.pf ppf "\n\t@@$(MAKE) -s depext-lockfile"
    | false -> ()
  and pp_add_repo ppf = function
    | Some _ -> Fmt.pf ppf "\n\t@@$(MAKE) -s repo-add"
    | None -> ()
  and pp_or_remove_repo ppf = function
    | Some _ -> Fmt.pf ppf " || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)"
    | None -> ()
  and pp_final_remove_repo ppf = function
    | Some _ ->
        Fmt.pf ppf
          " && $(MAKE) -s repo-rm || (ret=$$?; $(MAKE) -s repo-rm && exit \
           $$ret)"
    | None -> ()
  in
  Fmt.pf ppf
    {|-include Makefile.user
BUILD_DIR = %a
MIRAGE_DIR = %a
UNIKERNEL_NAME = %s
OPAM = opam

.PHONY: all depend depends clean build%a

all:: build

depend depends::$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
	@@echo " ↳ opam-monorepo pull"
	@@cd $(BUILD_DIR) && $(OPAM) monorepo pull -l %s/$(UNIKERNEL_NAME).opam.locked

$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam%a
	@@echo " ↳ opam install global dependencies"
	@@$(OPAM) install ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-install.opam --deps-only --yes%a
	@@echo " ↳ opam-monorepo lock"
	@@$(OPAM) monorepo lock --build-only $(UNIKERNEL_NAME) -l ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked --ocaml-version $(shell ocamlc --version) %a%a%a

build::
	mirage build

clean::
	mirage clean
|}
    Fpath.pp t.build_dir Fpath.pp mirage_dir t.unikernel_name pp_extra_rules t
    t.name pp_depext t.depext pp_add_repo t.extra_repo pp_or_remove_repo
    t.extra_repo pp_depext_lockfile t.depext pp_final_remove_repo t.extra_repo

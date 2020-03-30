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

type t = { depext : bool; name : string }

let v ~depext name = { depext; name }

let pp ppf t =
  let pp_depext ppf = function
    | true -> Fmt.pf ppf "\n\t$(DEPEXT)"
    | false -> ()
  in
  Fmt.pf ppf
    "-include Makefile.user\n\n\
     OPAM = opam\n\n\
     DEPEXT ?= $(OPAM) pin add -k path --no-action --yes %s . && \\\n\
     \t    $(OPAM) depext --yes --update %s ;\\\n\
     \t    $(OPAM) pin remove --no-action %s\n\n\
     .PHONY: all depend depends clean build\n\n\
     all:: build\n\n\
     depend depends::%a\n\
     \t$(OPAM) install -y --deps-only .\n\n\
     build::\n\
     \tmirage build\n\n\
     clean::\n\
     \tmirage clean\n"
    t.name t.name t.name pp_depext t.depext

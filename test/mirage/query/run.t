  $ export MIRAGE_DEFAULT_TARGET unix

Query name
  $ ./config.exe query name
  noop

Query opam
  $ ./config.exe query opam
  opam-version: "2.0"
  name: "noop"
  maintainer: "dummy"
  authors: "dummy"
  homepage: "dummy"
  bug-reports: "dummy"
  dev-repo: "git+https://example.com/nonexistent"
  synopsis: "This is a dummy"
  
  build: ["mirage" "build" "--config-file" "config.ml"]
  
  depends: [
    "lwt"
    "mirage" {build &  >= "3.10.0" & < "3.11.0"}
    "mirage-bootvar-unix" { >= "0.1.0" & < "0.2.0"}
    "mirage-clock-unix" { >= "3.0.0" & < "4.0.0"}
    "mirage-logs" { >= "1.2.0" & < "2.0.0"}
    "mirage-runtime" { >= "3.10.0" & < "3.11.0"}
    "mirage-types" { >= "3.10.0" & < "3.11.0"}
    "mirage-unix" { >= "4.0.0" & < "5.0.0"}
    "ocaml" {build &  >= "4.08.0"}
    "ocamlbuild" {build}
    "ocamlfind" {build}
  ]
  

Query packages
  $ ./config.exe query packages
  "lwt"
  "mirage" {build &  >= "3.10.0" & < "3.11.0"}
  "mirage-bootvar-unix" { >= "0.1.0" & < "0.2.0"}
  "mirage-clock-unix" { >= "3.0.0" & < "4.0.0"}
  "mirage-logs" { >= "1.2.0" & < "2.0.0"}
  "mirage-runtime" { >= "3.10.0" & < "3.11.0"}
  "mirage-types" { >= "3.10.0" & < "3.11.0"}
  "mirage-unix" { >= "4.0.0" & < "5.0.0"}
  "ocaml" {build &  >= "4.08.0"}
  "ocamlbuild" {build}
  "ocamlfind" {build}

Query files-configure
  $ ./config.exe query files-configure
  key_gen.ml main.ml myocamlbuild.ml

Query files-build
  $ ./config.exe query files-build
  main.native

Query Makefile
  $ ./config.exe query Makefile
  -include Makefile.user
  
  OPAM = opam
  
  DEPEXT ?= $(OPAM) pin add -k path --no-action --yes noop . && \
  	    $(OPAM) depext --yes --update noop ;\
  	    $(OPAM) pin remove --no-action noop
  
  .PHONY: all depend depends clean build
  
  all:: build
  
  depend depends::
  	$(DEPEXT)
  	$(OPAM) install -y --deps-only .
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  

Query Makefile without depexts
  $ ./config.exe query Makefile --no-depext
  -include Makefile.user
  
  OPAM = opam
  
  DEPEXT ?= $(OPAM) pin add -k path --no-action --yes noop . && \
  	    $(OPAM) depext --yes --update noop ;\
  	    $(OPAM) pin remove --no-action noop
  
  .PHONY: all depend depends clean build
  
  all:: build
  
  depend depends::
  	$(OPAM) install -y --deps-only .
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  

Query Makefile with depext
  $ ./config.exe query Makefile --depext
  -include Makefile.user
  
  OPAM = opam
  
  DEPEXT ?= $(OPAM) pin add -k path --no-action --yes noop . && \
  	    $(OPAM) depext --yes --update noop ;\
  	    $(OPAM) pin remove --no-action noop
  
  .PHONY: all depend depends clean build
  
  all:: build
  
  depend depends::
  	$(DEPEXT)
  	$(OPAM) install -y --deps-only .
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  
Query version
  $ ./config.exe query --version
  %%VERSION%%

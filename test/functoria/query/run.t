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
  
  build: ["test" "build" "--config-file" "config.ml"]
  
  depends: [
    "fmt"
    "functoria-runtime"
  ]
  

Query packages
  $ ./config.exe query packages
  "fmt"
  "functoria-runtime"

Query install
  $ ./config.exe query install
  bin: [
    "src/main.exe" {"noop"}
  ]
  etc: [
    "key/vote" {"vote"}
    "key/warn_error" {"warn_error"}
  ]

Query files-configure
  $ ./config.exe query files-configure
  key_gen.ml main.ml

Query files-build
  $ ./config.exe query files-build
  vote warn_error

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
  1.0~test

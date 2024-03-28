  $ export MIRAGE_DEFAULT_TARGET unix

Query name
  $ ./config.exe query name
  noop

Query opam file
  $ ./config.exe query opam -t unix
  opam-version: "2.0"
  maintainer: "dummy"
  authors: "dummy"
  homepage: "dummy"
  bug-reports: "dummy"
  dev-repo: "git://dummy"
  synopsis: "Unikernel noop - switch dependencies"
  description: """
  It assumes that local dependencies are already
  fetched.
  """

  build: ["sh" "-exc" "mirage build"]

  install: [
    [ "cp" "dist/noop" "%{bin}%/noop" ]
  ]

  depends: [
    "duration" { ?monorepo & < "1.0.0" }
    "lwt" { ?monorepo }
    "mirage" { ?monorepo & build & >= "4.4.0" & < "4.5.0" }
    "mirage-bootvar-unix" { ?monorepo & >= "0.1.0" & < "0.2.0" }
    "mirage-clock-unix" { ?monorepo & >= "3.0.0" & < "5.0.0" }
    "mirage-logs" { ?monorepo & >= "2.0.0" & < "3.0.0" }
    "mirage-runtime" { ?monorepo & >= "4.4.0" & < "4.5.0" }
    "mirage-unix" { ?monorepo & >= "5.0.0" & < "6.0.0" }
    "opam-monorepo" { build & >= "0.3.2" }
  ]

  x-mirage-opam-lock-location: "mirage/noop-unix.opam.locked"

  x-mirage-configure: ["sh" "-exc" "mirage configure -t unix --no-extra-repo"]

  x-mirage-pre-build: [make "lock" "depext-lockfile" "pull"]

  x-mirage-extra-repo: [
  ["opam-overlays" "git+https://github.com/dune-universe/opam-overlays.git"]

  ["mirage-overlays" "git+https://github.com/dune-universe/mirage-opam-overlays.git"]]

  x-opam-monorepo-opam-provided: ["opam-monorepo"]



Query packages
  $ ./config.exe query packages
  "duration" { ?monorepo & < "1.0.0" }
  "lwt" { ?monorepo }
  "mirage" { ?monorepo & build & >= "4.4.0" & < "4.5.0" }
  "mirage-bootvar-unix" { ?monorepo & >= "0.1.0" & < "0.2.0" }
  "mirage-clock-unix" { ?monorepo & >= "3.0.0" & < "5.0.0" }
  "mirage-logs" { ?monorepo & >= "2.0.0" & < "3.0.0" }
  "mirage-runtime" { ?monorepo & >= "4.4.0" & < "4.5.0" }
  "mirage-unix" { ?monorepo & >= "5.0.0" & < "6.0.0" }
  "opam-monorepo" { build & >= "0.3.2" }

Query files
  $ ./config.exe query files
  main.ml

Query Makefile
  $ ./config.exe query Makefile --target unix
  -include Makefile.user
  OPAM = opam
  OPAMS = $(shell find . -type f -name '*.opam' | grep -vE '(_build|_opam|duniverse)/')
  PROJECT = pkg
  LOCK_FILE = $(PROJECT).opam.locked

  REPOSITORIES = "[git+https://github.com/dune-universe/opam-overlays.git,git+https://github.com/dune-universe/mirage-opam-overlays.git,git+https://github.com/ocaml/opam-repository.git]"
  GLOBAL_VARS  = "[[opam-version,2.1.5],[monorepo,true]]"

  all:: depends build

  .PHONY: all lock install-switch pull clean depend depends build depext-lockfile


  depext-lockfile: install-switch
  	echo " ↳ install external dependencies for monorepo"
  	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo depext -y -l $(LOCK_FILE)


  $(LOCK_FILE): $(OPAMS)
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --require-cross-compile --build-only -l $@ --opam-repositories $(REPOSITORIES) -vv --recurse-opam --add-global-opam-vars $(GLOBAL_VARS) --ocaml-version $(shell ocamlc --version)

  lock:: $(LOCK_FILE)
  	@

  pull:: $(LOCK_FILE)
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $<

  install-switch:: $(OPAMS)
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes
  	@$(MAKE) -s depext-lockfile

  depends depend:: lock install-switch depext-lockfile pull

  build::
  	dune build --profile release --root .

  clean::
  	mirage clean



Query Makefile without depexts
  $ ./config.exe query Makefile --no-depext --target unix
  -include Makefile.user
  OPAM = opam
  OPAMS = $(shell find . -type f -name '*.opam' | grep -vE '(_build|_opam|duniverse)/')
  PROJECT = pkg
  LOCK_FILE = $(PROJECT).opam.locked

  REPOSITORIES = "[git+https://github.com/dune-universe/opam-overlays.git,git+https://github.com/dune-universe/mirage-opam-overlays.git,git+https://github.com/ocaml/opam-repository.git]"
  GLOBAL_VARS  = "[[opam-version,2.1.5],[monorepo,true]]"

  all:: depends build

  .PHONY: all lock install-switch pull clean depend depends build

  $(LOCK_FILE): $(OPAMS)
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --require-cross-compile --build-only -l $@ --opam-repositories $(REPOSITORIES) -vv --recurse-opam --add-global-opam-vars $(GLOBAL_VARS) --ocaml-version $(shell ocamlc --version)

  lock:: $(LOCK_FILE)
  	@

  pull:: $(LOCK_FILE)
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $<

  install-switch:: $(OPAMS)
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes --no-depexts

  depends depend:: lock install-switch depext-lockfile pull

  build::
  	dune build --profile release --root .

  clean::
  	mirage clean



Query Makefile with depext
  $ ./config.exe query Makefile --depext --target unix
  -include Makefile.user
  OPAM = opam
  OPAMS = $(shell find . -type f -name '*.opam' | grep -vE '(_build|_opam|duniverse)/')
  PROJECT = pkg
  LOCK_FILE = $(PROJECT).opam.locked

  REPOSITORIES = "[git+https://github.com/dune-universe/opam-overlays.git,git+https://github.com/dune-universe/mirage-opam-overlays.git,git+https://github.com/ocaml/opam-repository.git]"
  GLOBAL_VARS  = "[[opam-version,2.1.5],[monorepo,true]]"

  all:: depends build

  .PHONY: all lock install-switch pull clean depend depends build depext-lockfile


  depext-lockfile: install-switch
  	echo " ↳ install external dependencies for monorepo"
  	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo depext -y -l $(LOCK_FILE)


  $(LOCK_FILE): $(OPAMS)
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --require-cross-compile --build-only -l $@ --opam-repositories $(REPOSITORIES) -vv --recurse-opam --add-global-opam-vars $(GLOBAL_VARS) --ocaml-version $(shell ocamlc --version)

  lock:: $(LOCK_FILE)
  	@

  pull:: $(LOCK_FILE)
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $<

  install-switch:: $(OPAMS)
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes
  	@$(MAKE) -s depext-lockfile

  depends depend:: lock install-switch depext-lockfile pull

  build::
  	dune build --profile release --root .

  clean::
  	mirage clean

Query version
  $ ./config.exe query --version
  %%VERSION%%

Query dune to build the library
  $ ./config.exe query dune.lib
  (copy_files# ./mirage/main.ml)

  (rule
   (target noop)
   (enabled_if (= %{context_name} "default"))
   (deps main.exe)
   (action (copy main.exe %{target})))

  (executable
   (name main)
   (libraries duration lwt mirage-bootvar-unix mirage-clock-unix mirage-logs
     mirage-runtime mirage-unix)
   (link_flags (-thread))
   (modules (:standard \ config))
   (flags :standard -w -70)
   (enabled_if (= %{context_name} "default")))

  (subdir mirage
   (rule
    (targets dune.build.gen)
    (enabled_if (= %{context_name} "default"))
    (deps context ../config.exe)
    (action (with-stdout-to dune.build.gen
     (run ../config.exe query --context-file context dune.build))))

   (rule (alias dist)
    (enabled_if (= %{context_name} "default"))
    (action (diff dune.build dune.build.gen))))

  (subdir mirage
   (rule
    (targets dune.dist.gen)
    (enabled_if (= %{context_name} "default"))
    (deps context ../config.exe)
    (action (with-stdout-to dune.dist.gen
     (run ../config.exe query --context-file context dune.dist))))

   (rule (alias dist)
    (enabled_if (= %{context_name} "default"))
    (action (diff dune.build dune.build.gen))))

Query dune to build the application
  $ ./config.exe query dune.app

Query dune to build config.exe
  $ ./config.exe query dune.config
  (executable
   (name config)
   (enabled_if (= %{context_name} "default"))
   (modules config)
   (libraries mirage))

  (include mirage/dune.build)

  (subdir dist (include ../mirage/dune.dist))

  (include mirage/dune.build)

  (subdir dist (include ../mirage/dune.dist))

Query dune-project
  $ ./config.exe query dune-project --target unix
  (lang dune 2.9)
  (implicit_transitive_deps true)

Query dune-workspace
  $ ./config.exe query dune-workspace
  (lang dune 2.9)
  (context (default))

  (context (default
    (name solo5)
    (host default)
    (toolchain solo5)
    (merlin)
    (disable_dynamically_linked_foreign_archives true)))

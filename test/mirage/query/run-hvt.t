  $ export MIRAGE_DEFAULT_TARGET unix

Query opam file
  $ ./config.exe query --target hvt opam
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
    [ "cp" "dist/noop.hvt" "%{bin}%/noop.hvt" ]
  ]
  
  depends: [
    "duration" { ?monorepo & < "1.0.0" }
    "lwt" { ?monorepo }
    "mirage" { ?monorepo & build & >= "4.4.0" & < "4.5.0" }
    "mirage-bootvar-solo5" { ?monorepo & >= "0.6.0" & < "0.7.0" }
    "mirage-clock-solo5" { ?monorepo & >= "4.2.0" & < "5.0.0" }
    "mirage-logs" { ?monorepo & >= "2.0.0" & < "3.0.0" }
    "mirage-runtime" { ?monorepo & >= "4.4.0" & < "4.5.0" }
    "mirage-solo5" { ?monorepo & >= "0.9.0" & < "0.10.0" }
    "ocaml-solo5" { build & >= "0.8.1" & < "0.9.0" }
    "opam-monorepo" { build & >= "0.3.2" }
    "solo5" { build & >= "0.7.5" & < "0.9.0" }
  ]
  
  x-mirage-opam-lock-location: "mirage/noop-hvt.opam.locked"
  
  x-mirage-configure: ["sh" "-exc" "mirage configure --target hvt --no-extra-repo"]
  
  x-mirage-pre-build: [make "lock" "depext-lockfile" "pull"]
  
  x-mirage-extra-repo: [
  ["opam-overlays" "git+https://github.com/dune-universe/opam-overlays.git"]
  
  ["mirage-overlays" "git+https://github.com/dune-universe/mirage-opam-overlays.git"]]
  
  x-opam-monorepo-opam-provided: ["ocaml-solo5" "opam-monorepo" "solo5"]
  


Query packages
  $ ./config.exe query --target hvt packages
  "duration" { ?monorepo & < "1.0.0" }
  "lwt" { ?monorepo }
  "mirage" { ?monorepo & build & >= "4.4.0" & < "4.5.0" }
  "mirage-bootvar-solo5" { ?monorepo & >= "0.6.0" & < "0.7.0" }
  "mirage-clock-solo5" { ?monorepo & >= "4.2.0" & < "5.0.0" }
  "mirage-logs" { ?monorepo & >= "2.0.0" & < "3.0.0" }
  "mirage-runtime" { ?monorepo & >= "4.4.0" & < "4.5.0" }
  "mirage-solo5" { ?monorepo & >= "0.9.0" & < "0.10.0" }
  "ocaml-solo5" { build & >= "0.8.1" & < "0.9.0" }
  "opam-monorepo" { build & >= "0.3.2" }
  "solo5" { build & >= "0.7.5" & < "0.9.0" }

Query files
  $ ./config.exe query --target hvt files
  main.ml manifest.json manifest.ml

Query Makefile
  $ ./config.exe query --target hvt Makefile
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
  $ ./config.exe query --target hvt Makefile --no-depext
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
  $ ./config.exe query --target hvt Makefile --depext
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
  $ ./config.exe query --target hvt --version
  %%VERSION%%

Query unikernel dune
  $ ./config.exe query --target hvt dune.build
  (copy_files# ./mirage/main.ml)
  
  (copy_files ./mirage/manifest.json)
  
  (copy_files# ./mirage/manifest.ml)
  
  (executable
   (enabled_if (= %{context_name} "solo5"))
   (name main)
   (modes (native exe))
   (libraries duration lwt mirage-bootvar-solo5 mirage-clock-solo5 mirage-logs
     mirage-runtime mirage-solo5)
   (link_flags :standard -w -70 -cclib "-z solo5-abi=hvt")
   (modules (:standard \ config manifest))
   (foreign_stubs (language c) (names manifest)))
  
  (rule
   (targets manifest.c)
   (deps manifest.json)
   (action
    (run solo5-elftool gen-manifest manifest.json manifest.c)))
  
  (rule
   (target noop.hvt)
   (enabled_if (= %{context_name} "solo5"))
   (deps main.exe)
   (action
    (copy main.exe %{target})))
  
  (subdir mirage
   (rule
    (targets dune.build.gen)
    (deps context ../config.exe)
    (action (with-stdout-to dune.build.gen
     (run ../config.exe query --context-file context dune.build))))
  
   (rule (alias dist) (action (diff dune.build dune.build.gen))))
  
  (subdir mirage
   (rule
    (targets dune.dist.gen)
    (deps context ../config.exe)
    (action (with-stdout-to dune.dist.gen
     (run ../config.exe query --context-file context dune.dist))))
  
   (rule (alias dist) (action (diff dune.build dune.build.gen))))

Query configuration dune
  $ ./config.exe query --target hvt dune.config
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
  $ ./config.exe query --target hvt dune-project
  (lang dune 2.9)
  (implicit_transitive_deps true)

Query dune-workspace
  $ ./config.exe query --target hvt dune-workspace
  (lang dune 2.9)
  (context (default))
  
  (context (default
    (name solo5)
    (host default)
    (toolchain solo5)
    (merlin)
    (disable_dynamically_linked_foreign_archives true)))

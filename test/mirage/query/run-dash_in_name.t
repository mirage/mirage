Query unikernel dune
  $ ./config_dash_in_name.exe query dune.build
  (copy_files# ./mirage/main.ml)
  
  (rule
   (target noop-functor.v0)
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

Query dist dune
  $ ./config_dash_in_name.exe query dune.dist
  (rule
   (alias dist)
   (mode (promote (until-clean)))
   (target noop-functor.v0)
   (enabled_if (= %{context_name} "default"))
   (action (copy ../noop-functor.v0 %{target})))

Query makefile
  $ ./config_dash_in_name.exe query Makefile --target unix
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
  
...

Query dune-project
  $ ./config_dash_in_name.exe query dune-project --target unix
  (lang dune 2.9)
  (implicit_transitive_deps true)

Query unikernel dune (hvt)
  $ ./config_dash_in_name.exe query --target hvt dune.build
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
   (target noop-functor.v0.hvt)
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

Query dist dune (hvt)
  $ ./config_dash_in_name.exe query --target hvt dune.dist
  (rule
   (alias dist)
   (mode (promote (until-clean)))
   (target noop-functor.v0.hvt)
   (enabled_if (= %{context_name} "solo5"))
   (action (copy ../noop-functor.v0.hvt %{target})))

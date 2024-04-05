Query dune to build the library
  $ ./config_dash_in_name.exe query dune.lib
  (include dune.config)
  
  (library
    (name noop_functor_v0)
    (libraries logs lwt)
    (wrapped false)
    (modules (:standard \ config)))
  
  (rule (copy mirage/main.exe main.exe))
  
  (subdir dist (include ../mirage/dune.dist))

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
  (lang dune 3.0)
  (using directory-targets 0.1)

Query unikernel dune (hvt)
  $ ./config_dash_in_name.exe query --target hvt dune.build
  mirage: INFO argument: invalid value 'dune.build', expected one of 'name',
          'packages', 'opam', 'files', 'Makefile', 'dune.config', 'dune.lib',
          'dune.app', 'dune.dist', 'dune-project' or 'dune-workspace'
  Usage: mirage query [OPTION]… [INFO]
  Try 'mirage query --help' or 'mirage --help' for more information.
  [1]

Query dist dune (hvt)
  $ ./config_dash_in_name.exe query --target hvt dune.dist
  (rule
   (alias dist)
   (mode (promote (until-clean)))
   (target noop-functor.v0.hvt)
   (enabled_if (= %{context_name} "solo5"))
   (action (copy ../noop-functor.v0.hvt %{target})))

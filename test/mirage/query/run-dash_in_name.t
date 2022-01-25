Query unikernel dune
  $ ./config_dash_in_name.exe query dune.build
  (copy_files ./config/*)
  
  (rule
   (target noop-functor.v0)
   (enabled_if (= %{context_name} "default"))
   (action
    (copy main.exe %{target})))
  
  (executable
   (name main)
   (libraries lwt mirage-bootvar-unix mirage-clock-unix mirage-logs
     mirage-runtime mirage-unix)
   (link_flags (-thread))
   (modules (:standard \ config))
   (flags -g -w +A-4-41-42-44 -bin-annot -strict-sequence -principal
     -safe-string)
   (enabled_if (= %{context_name} "default"))
  )

Query dist dune
  $ ./config_dash_in_name.exe query dune.dist
  (rule
   (mode (promote (until-clean)))
   (target noop-functor.v0)
   (enabled_if (= %{context_name} "default"))
   (action
    (copy ../noop-functor.v0 %{target}))
  )

Query makefile
  $ ./config_dash_in_name.exe query Makefile
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop-functor_v0-unix
  OPAM = opam
  
  all::
  	@$(MAKE) --no-print-directory depends
  	@$(MAKE) --no-print-directory build
  
  .PHONY: all lock install-switch pull clean depend depends build mirage-repo-add mirage-repo-rm repo-add repo-rm depext-lockfile
  
  repo-add:
  	@echo -e "\e[2musing overlay repository mirage: [opam-overlays, mirage-overlays] \e[0m"
  	$(OPAM) repo add opam-overlays https://github.com/dune-universe/opam-overlays.git || $(OPAM) repo set-url opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo add mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git || $(OPAM) repo set-url mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  repo-rm:
  	@echo -e "\e[2mremoving overlay repository [opam-overlays, mirage-overlays]\e[0m"
  	$(OPAM) repo remove opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo remove mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  
  depext-lockfile: $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked
  	echo " ↳ install external dependencies for monorepo"
  	$(OPAM) monorepo depext -y -l $<
  
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --build-only $(UNIKERNEL_NAME)-monorepo -l $@ --ocaml-version $(shell ocamlc --version); (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  lock::
  	@$(MAKE) -B $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked
  	@echo " ↳ fetch monorepo rependencies in the duniverse folder"
  	@cd $(BUILD_DIR) && $(OPAM) monorepo pull -l $<
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-switch.opam
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes
  	@$(MAKE) -s depext-lockfile
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  
...

Query dune-project
  $ ./config_dash_in_name.exe query dune-project
  (lang dune 2.7)
  
  (name noop-functor.v0-unix)
  
  (implicit_transitive_deps true)

Query unikernel dune (hvt)
  $ ./config_dash_in_name.exe query --target hvt dune.build
  (copy_files ./config/*)
  
  (executable
   (enabled_if (= %{context_name} "freestanding"))
   (name main)
   (modes (native exe))
   (libraries lwt mirage-bootvar-solo5 mirage-clock-freestanding mirage-logs
     mirage-runtime mirage-solo5)
   (link_flags -g -w +A-4-41-42-44 -bin-annot -strict-sequence -principal
     -safe-string -cclib "-z solo5-abi=hvt")
   (modules (:standard \ config manifest))
   (foreign_stubs (language c) (names manifest))
  )
  
  (rule
   (targets manifest.c)
   (deps manifest.json)
   (action
    (run solo5-elftool gen-manifest manifest.json manifest.c)))
  
  (rule
   (target noop-functor.v0.hvt)
   (enabled_if (= %{context_name} "freestanding"))
   (deps main.exe)
   (action
    (copy main.exe %{target})))
  
  (alias
    (name default)
    (enabled_if (= %{context_name} "freestanding"))
    (deps (alias_rec all))
    )

Query dist dune (hvt)
  $ ./config_dash_in_name.exe query --target hvt dune.dist
  (rule
   (mode (promote (until-clean)))
   (target noop-functor.v0.hvt)
   (enabled_if (= %{context_name} "freestanding"))
   (action
    (copy ../noop-functor.v0.hvt %{target}))
  )

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
  
  all:: build
  
  .PHONY: all depend depends clean build repo-add repo-rm depext-lockfile
  
  repo-add:
  	echo -e "\e[2musing overlay repository mirage-tmp: https://github.com/mirage/opam-overlays.git \e[0m"
  	$(OPAM) repo add mirage-tmp https://github.com/mirage/opam-overlays.git ||\
  	$(OPAM) repo set-url mirage-tmp https://github.com/mirage/opam-overlays.git
  
  repo-rm:
  	echo -e "\e[2mremoving overlay repository mirage-tmp\e[0m"
  	$(OPAM) repo remove mirage-tmp
  
  
  depext-lockfile:
  	echo " ↳ lockfile depexts"
  	opam install --cli 2.1 --ignore-pin-depends --depext-only --locked $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked
  
  
  depend depends::$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked
  	@echo " ↳ fetch monorepo rependencies in the duniverse folder"
  	@cd $(BUILD_DIR) && $(OPAM) monorepo pull -l mirage/$(UNIKERNEL_NAME)-monorepo.opam.locked
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-switch.opam --deps-only --yes
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --build-only $(UNIKERNEL_NAME)-monorepo -l ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked --ocaml-version $(shell ocamlc --version)  || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  	@$(MAKE) -s depext-lockfile && $(MAKE) -s repo-rm || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
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
   (enabled_if (= %{context_name} "mirage-hvt"))
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
   (enabled_if (= %{context_name} "mirage-hvt"))
   (deps main.exe)
   (action
    (copy main.exe %{target})))
  
  (alias
    (name default)
    (enabled_if (= %{context_name} "mirage-hvt"))
    (deps (alias_rec all))
    )

Query dist dune (hvt)
  $ ./config_dash_in_name.exe query --target hvt dune.dist
  (rule
   (mode (promote (until-clean)))
   (target noop-functor.v0.hvt)
   (enabled_if (= %{context_name} "mirage-hvt"))
   (action
    (copy ../noop-functor.v0.hvt %{target}))
  )

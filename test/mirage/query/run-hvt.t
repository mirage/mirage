  $ export MIRAGE_DEFAULT_TARGET unix

Query global opam
  $ ./config.exe query --target hvt switch.opam
  opam-version: "2.0"
  name: "noop"
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
  
  build: [
    [ "mirage" "configure" "--target" "hvt" ]
    [ "mirage" "build" ]
  ]
  
  install: [
    [ "cp" "dist/noop.hvt" "%{bin}%/noop.hvt" ]
  ]
  
  depends: [
    "ocaml-freestanding" { build }
  ]
  

Query local opam
  $ ./config.exe query --target hvt monorepo.opam
  opam-version: "2.0"
  name: "noop"
  maintainer: "dummy"
  authors: "dummy"
  homepage: "dummy"
  bug-reports: "dummy"
  dev-repo: "git://dummy"
  synopsis: "Unikernel noop - monorepo dependencies"
  
  depends: [
    "lwt"
    "mirage" { build & >= "4.0.0" & < "4.1.0" }
    "mirage-bootvar-solo5" { >= "0.6.0" & < "0.7.0" }
    "mirage-clock-freestanding" { >= "3.1.0" & < "4.0.0" }
    "mirage-logs" { >= "1.2.0" & < "2.0.0" }
    "mirage-runtime" { >= "4.0.0" & < "4.1.0" }
    "mirage-solo5" { >= "0.7.0" & < "0.8.0" }
    "ocaml" { build & >= "4.08.0" }
  ]
  
  

Query packages
  $ ./config.exe query --target hvt packages
  "lwt"
  "mirage" { build & >= "4.0.0" & < "4.1.0" }
  "mirage-bootvar-solo5" { >= "0.6.0" & < "0.7.0" }
  "mirage-clock-freestanding" { >= "3.1.0" & < "4.0.0" }
  "mirage-logs" { >= "1.2.0" & < "2.0.0" }
  "mirage-runtime" { >= "4.0.0" & < "4.1.0" }
  "mirage-solo5" { >= "0.7.0" & < "0.8.0" }
  "ocaml" { build & >= "4.08.0" }
  "ocaml-freestanding" { build }

Query files
  $ ./config.exe query --target hvt files
  key_gen.ml main.ml manifest.json manifest.ml

Query Makefile
  $ ./config.exe query --target hvt Makefile
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop
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
  

Query Makefile without depexts
  $ ./config.exe query --target hvt Makefile --no-depext
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop
  OPAM = opam
  
  all:: build
  
  .PHONY: all depend depends clean build repo-add repo-rm
  
  repo-add:
  	echo -e "\e[2musing overlay repository mirage-tmp: https://github.com/mirage/opam-overlays.git \e[0m"
  	$(OPAM) repo add mirage-tmp https://github.com/mirage/opam-overlays.git ||\
  	$(OPAM) repo set-url mirage-tmp https://github.com/mirage/opam-overlays.git
  
  repo-rm:
  	echo -e "\e[2mremoving overlay repository mirage-tmp\e[0m"
  	$(OPAM) repo remove mirage-tmp
  
  depend depends::$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked
  	@echo " ↳ fetch monorepo rependencies in the duniverse folder"
  	@cd $(BUILD_DIR) && $(OPAM) monorepo pull -l mirage/$(UNIKERNEL_NAME)-monorepo.opam.locked
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-switch.opam --deps-only --yes --no-depexts
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --build-only $(UNIKERNEL_NAME)-monorepo -l ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-monorepo.opam.locked --ocaml-version $(shell ocamlc --version)  || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret) && $(MAKE) -s repo-rm || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  

Query Makefile with depext
  $ ./config.exe query --target hvt Makefile --depext
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop
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
  
Query version
  $ ./config.exe query --target hvt --version
  %%VERSION%%

Query unikernel dune
  $ ./config.exe query --target hvt dune.build
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
   (target noop.hvt)
   (enabled_if (= %{context_name} "mirage-hvt"))
   (deps main.exe)
   (action
    (copy main.exe %{target})))
  
  (alias
    (name default)
    (enabled_if (= %{context_name} "mirage-hvt"))
    (deps (alias_rec all))
    )

Query configuration dune
  $ ./config.exe query --target hvt dune.config
  (data_only_dirs duniverse)
  
  ;; Generated by mirage.%%VERSION%%
  
  
  (executable
   (name config)
   (flags (:standard -warn-error -A))
   (modules config)
   (libraries mirage))

Query dune-project
  $ ./config.exe query --target hvt dune-project
  (lang dune 2.7)
  
  (name noop-hvt)
  
  (implicit_transitive_deps true)

Query dune-workspace
  $ ./config.exe query --target hvt dune-workspace
  (lang dune 2.0)
  
  (context (default))
  
  (profile release)
  
  (context (default
    (name mirage-hvt)
    (host default)
    (toolchain freestanding)
    (disable_dynamically_linked_foreign_archives true)
    ))

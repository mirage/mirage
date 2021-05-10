  $ export MIRAGE_DEFAULT_TARGET unix

Query name
  $ ./config.exe query name
  noop

Query global opam
  $ ./config.exe query global.opam
  opam-version: "2.0"
  name: "noop"
  maintainer: "dummy"
  authors: "dummy"
  homepage: "dummy"
  bug-reports: "dummy"
  dev-repo: "git://dummy"
  synopsis: "Unikernel noop - main opam file"
  description: """
  It assumes that local dependencies are already
  fetched.
  """
  
  build: [
    [ "mirage" "configure"  ]
    [ "mirage" "build" ]
  ]
  
  install: [
    [ "cp" "dist/noop" "%{bin}%/noop" ]
  ]
  
  depends: [
    
  ]
  

Query local opam
  $ ./config.exe query local.opam
  opam-version: "2.0"
  name: "noop"
  maintainer: "dummy"
  authors: "dummy"
  homepage: "dummy"
  bug-reports: "dummy"
  dev-repo: "git://dummy"
  synopsis: "Unikernel noop - local dependencies"
  
  depends: [
    "lwt"
    "mirage" { build & >= "4.0.0" & < "4.1.0" }
    "mirage-bootvar-unix" { >= "0.1.0" & < "0.2.0" }
    "mirage-clock-unix" { >= "3.0.0" & < "4.0.0" }
    "mirage-logs" { >= "1.2.0" & < "2.0.0" }
    "mirage-runtime" { >= "4.0.0" & < "4.1.0" }
    "mirage-unix" { >= "4.0.1" & < "5.0.0" }
    "ocaml" { build & >= "4.08.0" }
  ]
  
  
Query packages
  $ ./config.exe query packages
  "lwt"
  "mirage" { build & >= "4.0.0" & < "4.1.0" }
  "mirage-bootvar-unix" { >= "0.1.0" & < "0.2.0" }
  "mirage-clock-unix" { >= "3.0.0" & < "4.0.0" }
  "mirage-logs" { >= "1.2.0" & < "2.0.0" }
  "mirage-runtime" { >= "4.0.0" & < "4.1.0" }
  "mirage-unix" { >= "4.0.1" & < "5.0.0" }
  "ocaml" { build & >= "4.08.0" }

Query files
  $ ./config.exe query files
  key_gen.ml main.ml

Query Makefile
  $ ./config.exe query Makefile
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop
  OPAM = opam
  
  .PHONY: all depend depends clean build repo-add repo-rm depext depext-lockfile
  
  repo-add:
  	echo -e "\e[2musing overlay repository mirage-tmp: https://github.com/mirage/opam-overlays.git \e[0m"
  	$(OPAM) repo add mirage-tmp https://github.com/mirage/opam-overlays.git ||\
  	$(OPAM) repo set-url mirage-tmp https://github.com/mirage/opam-overlays.git
  
  repo-rm:
  	echo -e "\e[2mremoving overlay repository mirage-tmp\e[0m"
  	$(OPAM) repo remove mirage-tmp
  
  depext:
  	echo " ↳ opam depexts"
  ifneq (,$(findstring 2.0.,$(shell opam --version)))
  	$(OPAM) pin add -k path --no-action --yes $(UNIKERNEL_NAME)-install $(MIRAGE_DIR)
  	$(OPAM) depext --yes --update $(UNIKERNEL_NAME)-install
  	$(OPAM) pin remove --no-action $(UNIKERNEL_NAME)-install
  else
  	opam install --cli 2.1 --depext-only $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-install.opam
  endif
  
  depext-lockfile:
  	echo " ↳ lockfile depexts"
  ifneq (,$(findstring 2.0.,$(shell opam --version)))
  	$(OPAM) pin add -k path --no-action --yes $(UNIKERNEL_NAME) $(MIRAGE_DIR) --locked --ignore-pin-depends
  	$(OPAM) depext --yes --update $(UNIKERNEL_NAME)
  	$(OPAM) pin remove --no-action $(UNIKERNEL_NAME)
  else
  	opam install --cli 2.1 --ignore-pin-depends --depext-only --locked $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  endif
  
  
  
  all:: build
  
  depend depends::$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ opam-monorepo pull"
  	@cd $(BUILD_DIR) && $(OPAM) monorepo pull -l mirage/$(UNIKERNEL_NAME).opam.locked
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@$(MAKE) -s depext
  	@echo " ↳ opam install global dependencies"
  	@$(OPAM) install ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-install.opam --deps-only --yes
  	@$(MAKE) -s repo-add
  	@echo " ↳ opam-monorepo lock"
  	@$(OPAM) monorepo lock --build-only $(UNIKERNEL_NAME) -l ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked --ocaml-version $(shell ocamlc --version)  || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  	@$(MAKE) -s depext-lockfile && $(MAKE) -s repo-rm || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  

Query Makefile without depexts
  $ ./config.exe query Makefile --no-depext
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop
  OPAM = opam
  
  .PHONY: all depend depends clean build repo-add repo-rm
  
  repo-add:
  	echo -e "\e[2musing overlay repository mirage-tmp: https://github.com/mirage/opam-overlays.git \e[0m"
  	$(OPAM) repo add mirage-tmp https://github.com/mirage/opam-overlays.git ||\
  	$(OPAM) repo set-url mirage-tmp https://github.com/mirage/opam-overlays.git
  
  repo-rm:
  	echo -e "\e[2mremoving overlay repository mirage-tmp\e[0m"
  	$(OPAM) repo remove mirage-tmp
  
  all:: build
  
  depend depends::$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ opam-monorepo pull"
  	@cd $(BUILD_DIR) && $(OPAM) monorepo pull -l mirage/$(UNIKERNEL_NAME).opam.locked
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@echo " ↳ opam install global dependencies"
  	@$(OPAM) install ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-install.opam --deps-only --yes
  	@$(MAKE) -s repo-add
  	@echo " ↳ opam-monorepo lock"
  	@$(OPAM) monorepo lock --build-only $(UNIKERNEL_NAME) -l ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked --ocaml-version $(shell ocamlc --version)  || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret) && $(MAKE) -s repo-rm || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  

Query Makefile with depext
  $ ./config.exe query Makefile --depext
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop
  OPAM = opam
  
  .PHONY: all depend depends clean build repo-add repo-rm depext depext-lockfile
  
  repo-add:
  	echo -e "\e[2musing overlay repository mirage-tmp: https://github.com/mirage/opam-overlays.git \e[0m"
  	$(OPAM) repo add mirage-tmp https://github.com/mirage/opam-overlays.git ||\
  	$(OPAM) repo set-url mirage-tmp https://github.com/mirage/opam-overlays.git
  
  repo-rm:
  	echo -e "\e[2mremoving overlay repository mirage-tmp\e[0m"
  	$(OPAM) repo remove mirage-tmp
  
  depext:
  	echo " ↳ opam depexts"
  ifneq (,$(findstring 2.0.,$(shell opam --version)))
  	$(OPAM) pin add -k path --no-action --yes $(UNIKERNEL_NAME)-install $(MIRAGE_DIR)
  	$(OPAM) depext --yes --update $(UNIKERNEL_NAME)-install
  	$(OPAM) pin remove --no-action $(UNIKERNEL_NAME)-install
  else
  	opam install --cli 2.1 --depext-only $(MIRAGE_DIR)/$(UNIKERNEL_NAME)-install.opam
  endif
  
  depext-lockfile:
  	echo " ↳ lockfile depexts"
  ifneq (,$(findstring 2.0.,$(shell opam --version)))
  	$(OPAM) pin add -k path --no-action --yes $(UNIKERNEL_NAME) $(MIRAGE_DIR) --locked --ignore-pin-depends
  	$(OPAM) depext --yes --update $(UNIKERNEL_NAME)
  	$(OPAM) pin remove --no-action $(UNIKERNEL_NAME)
  else
  	opam install --cli 2.1 --ignore-pin-depends --depext-only --locked $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  endif
  
  
  
  all:: build
  
  depend depends::$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ opam-monorepo pull"
  	@cd $(BUILD_DIR) && $(OPAM) monorepo pull -l mirage/$(UNIKERNEL_NAME).opam.locked
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@$(MAKE) -s depext
  	@echo " ↳ opam install global dependencies"
  	@$(OPAM) install ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME)-install.opam --deps-only --yes
  	@$(MAKE) -s repo-add
  	@echo " ↳ opam-monorepo lock"
  	@$(OPAM) monorepo lock --build-only $(UNIKERNEL_NAME) -l ./$(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked --ocaml-version $(shell ocamlc --version)  || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  	@$(MAKE) -s depext-lockfile && $(MAKE) -s repo-rm || (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  
Query version
  $ ./config.exe query --version
  %%VERSION%%

Query unikernel dune
  $ ./config.exe query dune.build
  (copy_files ./config/*)
  
  (rule
   (target noop)
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

Query configuration dune
  $ ./config.exe query dune.config
  (data_only_dirs duniverse)
  
  ;; Generated by mirage.%%VERSION%%
  
  
  (executable
   (name config)
   (flags (:standard -warn-error -A))
   (modules config)
   (libraries mirage))

Query dune-project
  $ ./config.exe query dune-project
  (lang dune 2.7)
  
  (name noop-unix)
  
  (implicit_transitive_deps true)

Query dune-workspace
  $ ./config.exe query dune-workspace
  (lang dune 2.0)
  
  (context (default))

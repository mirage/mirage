Query name
  $ ./config.exe query name
  noop

Query global opam
  $ ./config.exe query switch.opam
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
    [ "test" "configure"  ]
    [ "test" "build" ]
  ]
  
  install: [
    [ "cp" "dist/f0.exe" "%{bin}%/f0" ]
  ]
  
  depends: [
    
  ]
  


Query local opam
  $ ./config.exe query monorepo.opam
  opam-version: "2.0"
  name: "noop"
  maintainer: "dummy"
  authors: "dummy"
  homepage: "dummy"
  bug-reports: "dummy"
  dev-repo: "git://dummy"
  synopsis: "Unikernel noop - monorepo dependencies"
  
  depends: [
    "dune-build-info"
    "fmt"
    "functoria-runtime"
  ]
  
  


Query packages
  $ ./config.exe query packages
  "dune-build-info"
  "fmt"
  "functoria-runtime"

Query files
  $ ./config.exe query files
  info_gen.ml key_gen.ml main.ml vote warn_error

Query Makefile
  $ ./config.exe query Makefile
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./test
  UNIKERNEL_NAME = noop
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
  


Query Makefile without depexts
  $ ./config.exe query Makefile --no-depext
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./test
  UNIKERNEL_NAME = noop
  OPAM = opam
  
  all::
  	@$(MAKE) --no-print-directory depends
  	@$(MAKE) --no-print-directory build
  
  .PHONY: all lock install-switch pull clean depend depends build mirage-repo-add mirage-repo-rm repo-add repo-rm
  
  repo-add:
  	@echo -e "\e[2musing overlay repository mirage: [opam-overlays, mirage-overlays] \e[0m"
  	$(OPAM) repo add opam-overlays https://github.com/dune-universe/opam-overlays.git || $(OPAM) repo set-url opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo add mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git || $(OPAM) repo set-url mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  repo-rm:
  	@echo -e "\e[2mremoving overlay repository [opam-overlays, mirage-overlays]\e[0m"
  	$(OPAM) repo remove opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo remove mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
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
  	@$(OPAM) install $< --deps-only --yes --no-depexts
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  


Query Makefile with depext
  $ ./config.exe query Makefile --depext
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./test
  UNIKERNEL_NAME = noop
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
  

Query version
  $ ./config.exe query --version
  1.0~test

Query unikernel dune
  $ ./config.exe query dune.build
  (copy_files ./config/*)
  
  (executable
    (public_name f0)
    (package   functoria)
    (name      main)
    (modules   (:standard \ config))
    (promote   (until-clean))
    (libraries cmdliner fmt functoria-runtime))

Query configuration dune
  $ ./config.exe query dune.config
  (data_only_dirs duniverse)
  
  ;; Generated by test.1.0~test
  
  
  (executable
   (name config)
   (flags (:standard -warn-error -A))
   (modules config)
   (libraries f0 functoria))

Query dune-project
  $ ./config.exe query dune-project
  (lang dune 2.7)
  
  (name noop)

Query dune-workspace
  $ ./config.exe query dune-workspace
  (lang dune 2.0)
  (context default)

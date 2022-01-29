  $ export MIRAGE_DEFAULT_TARGET unix

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
    [ "mirage" "configure"  ]
    [ "mirage" "build" ]
  ]
  
  install: [
    [ "cp" "dist/noop" "%{bin}%/noop" ]
  ]
  
  depends: [
    "mirage" { build & >= "4.0.0" & < "4.1.0" }
    "ocaml" { build & >= "4.08.0" }
    "opam-monorepo" { build & >= "0.2.6" }
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
    "lwt"
    "mirage-bootvar-unix" { >= "0.1.0" & < "0.2.0" }
    "mirage-clock-unix" { >= "3.0.0" & < "5.0.0" }
    "mirage-logs" { >= "1.2.0" & < "2.0.0" }
    "mirage-runtime" { >= "4.0.0" & < "4.1.0" }
    "mirage-unix" { >= "5.0.0" & < "6.0.0" }
  ]
  
  


Query packages
  $ ./config.exe query packages
  "lwt"
  "mirage" { build & >= "4.0.0" & < "4.1.0" }
  "mirage-bootvar-unix" { >= "0.1.0" & < "0.2.0" }
  "mirage-clock-unix" { >= "3.0.0" & < "5.0.0" }
  "mirage-logs" { >= "1.2.0" & < "2.0.0" }
  "mirage-runtime" { >= "4.0.0" & < "4.1.0" }
  "mirage-unix" { >= "5.0.0" & < "6.0.0" }
  "ocaml" { build & >= "4.08.0" }
  "opam-monorepo" { build & >= "0.2.6" }

Query files
  $ ./config.exe query files
  key_gen.ml main.ml

Query Makefile
  $ ./config.exe query Makefile --target unix
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop-unix
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
  	@$(OPAM) monorepo pull -l $< -r $(BUILD_DIR)
  
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
  $ ./config.exe query Makefile --no-depext --target unix
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop-unix
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
  	@$(OPAM) monorepo pull -l $< -r $(BUILD_DIR)
  
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
  $ ./config.exe query Makefile --depext --target unix
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop-unix
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
  	@$(OPAM) monorepo pull -l $< -r $(BUILD_DIR)
  
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
  $ ./config.exe query dune-project --target unix
  (lang dune 2.7)
  
  (name noop-unix)
  
  (implicit_transitive_deps true)

Query dune-workspace
  $ ./config.exe query dune-workspace
  (lang dune 2.0)
  
  (context (default))

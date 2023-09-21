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
    "mirage" { build & >= "4.4.0" & < "4.5.0" }
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
  ["opam-overlays" "https://github.com/dune-universe/opam-overlays.git"]
  
  ["mirage-overlays" "https://github.com/dune-universe/mirage-opam-overlays.git"]]
  
  x-opam-monorepo-opam-provided: ["mirage"
  "opam-monorepo"]
  


Query packages
  $ ./config.exe query packages
  "duration" { ?monorepo & < "1.0.0" }
  "lwt" { ?monorepo }
  "mirage" { build & >= "4.4.0" & < "4.5.0" }
  "mirage-bootvar-unix" { ?monorepo & >= "0.1.0" & < "0.2.0" }
  "mirage-clock-unix" { ?monorepo & >= "3.0.0" & < "5.0.0" }
  "mirage-logs" { ?monorepo & >= "2.0.0" & < "3.0.0" }
  "mirage-runtime" { ?monorepo & >= "4.4.0" & < "4.5.0" }
  "mirage-unix" { ?monorepo & >= "5.0.0" & < "6.0.0" }
  "opam-monorepo" { build & >= "0.3.2" }

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
  
  .PHONY: all lock install-switch pull clean depend depends build repo-add repo-rm depext-lockfile
  
  repo-add:
  	@printf "\033[2musing overlay repository mirage: [opam-overlays, mirage-overlays] \033[0m\n"
  	$(OPAM) repo add opam-overlays https://github.com/dune-universe/opam-overlays.git || $(OPAM) repo set-url opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo add mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git || $(OPAM) repo set-url mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  repo-rm:
  	@printf "\033[2mremoving overlay repository [opam-overlays, mirage-overlays]\033[0m\n"
  	$(OPAM) repo remove opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo remove mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  
  depext-lockfile: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	echo " ↳ install external dependencies for monorepo"
  	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo depext -y -l $<
  
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo lock --require-cross-compile --build-only $(UNIKERNEL_NAME) -l $@ --ocaml-version $(shell ocamlc --version); (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  lock::
  	@$(MAKE) -B $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes
  	@$(MAKE) -s depext-lockfile
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	dune build --root . $(BUILD_DIR)dist
  
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
  
  .PHONY: all lock install-switch pull clean depend depends build repo-add repo-rm
  
  repo-add:
  	@printf "\033[2musing overlay repository mirage: [opam-overlays, mirage-overlays] \033[0m\n"
  	$(OPAM) repo add opam-overlays https://github.com/dune-universe/opam-overlays.git || $(OPAM) repo set-url opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo add mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git || $(OPAM) repo set-url mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  repo-rm:
  	@printf "\033[2mremoving overlay repository [opam-overlays, mirage-overlays]\033[0m\n"
  	$(OPAM) repo remove opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo remove mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo lock --require-cross-compile --build-only $(UNIKERNEL_NAME) -l $@ --ocaml-version $(shell ocamlc --version); (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  lock::
  	@$(MAKE) -B $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes --no-depexts
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	dune build --root . $(BUILD_DIR)dist
  
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
  
  .PHONY: all lock install-switch pull clean depend depends build repo-add repo-rm depext-lockfile
  
  repo-add:
  	@printf "\033[2musing overlay repository mirage: [opam-overlays, mirage-overlays] \033[0m\n"
  	$(OPAM) repo add opam-overlays https://github.com/dune-universe/opam-overlays.git || $(OPAM) repo set-url opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo add mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git || $(OPAM) repo set-url mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  repo-rm:
  	@printf "\033[2mremoving overlay repository [opam-overlays, mirage-overlays]\033[0m\n"
  	$(OPAM) repo remove opam-overlays https://github.com/dune-universe/opam-overlays.git
  	$(OPAM) repo remove mirage-overlays https://github.com/dune-universe/mirage-opam-overlays.git
  
  
  
  depext-lockfile: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	echo " ↳ install external dependencies for monorepo"
  	env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo depext -y -l $<
  
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo lock --require-cross-compile --build-only $(UNIKERNEL_NAME) -l $@ --ocaml-version $(shell ocamlc --version); (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  lock::
  	@$(MAKE) -B $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes
  	@$(MAKE) -s depext-lockfile
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	dune build --root . $(BUILD_DIR)dist
  
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
   (libraries duration lwt mirage-bootvar-unix mirage-clock-unix mirage-logs
     mirage-runtime mirage-unix)
   (link_flags (-thread))
   (modules (:standard \ config))
   (flags :standard -w -70)
   (enabled_if (= %{context_name} "default"))
  )

Query configuration dune
  $ ./config.exe query dune.config
  (data_only_dirs duniverse)
  
  ;; Generated by mirage.%%VERSION%%
  
  
  (executable
   (name config)
   (modules config)
   (libraries mirage))

Query dune-project
  $ ./config.exe query dune-project --target unix
  (lang dune 2.9)
  
  (name noop-unix)
  
  (implicit_transitive_deps true)

Query dune-workspace
  $ ./config.exe query dune-workspace
  (lang dune 2.0)
  
  (context (default))

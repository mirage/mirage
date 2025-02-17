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
  
  build: [make "build"]
  
  install: [
    [ "cp" "dist/noop" "%{bin}%/noop" ]
  ]
  
  depends: [
    "cmdliner-stdlib" { ?monorepo & >= "1.0.1" & < "2.0.0" }
    "duration" { ?monorepo & < "1.0.0" }
    "lwt" { ?monorepo }
    "mirage" { build & >= "4.9.0" & < "4.10.0" }
    "mirage-bootvar" { ?monorepo & >= "1.0.0" & < "2.0.0" }
    "mirage-crypto-rng-mirage" { ?monorepo & >= "2.0.0" & < "3.0.0" }
    "mirage-logs" { ?monorepo & >= "3.0.0" & < "4.0.0" }
    "mirage-mtime" { ?monorepo & >= "5.0.0" & < "6.0.0" }
    "mirage-ptime" { ?monorepo & >= "5.0.0" & < "6.0.0" }
    "mirage-runtime" { ?monorepo & >= "4.9.0" & < "4.10.0" }
    "mirage-sleep" { ?monorepo & >= "4.0.0" & < "5.0.0" }
    "mirage-unix" { ?monorepo & >= "5.0.0" & < "6.0.0" }
    "opam-monorepo" { build & >= "0.3.2" }
  ]
  
  x-mirage-opam-lock-location: "mirage/noop-unix.opam.locked"
  
  x-mirage-configure: ["sh" "-exc" "mirage configure -t unix --no-extra-repo"]
  
  x-mirage-pre-build: [make "lock" "depext-lockfile" "pull"]
  
  x-mirage-extra-repo: [
  ["opam-overlays" "https://github.com/dune-universe/opam-overlays.git"]
  
  ["mirage-overlays" "https://github.com/dune-universe/mirage-opam-overlays.git"]]
  
  x-opam-monorepo-opam-provided: ["mirage" "opam-monorepo"]
  


Query packages
  $ ./config.exe query packages
  "cmdliner-stdlib" { ?monorepo & >= "1.0.1" & < "2.0.0" }
  "duration" { ?monorepo & < "1.0.0" }
  "lwt" { ?monorepo }
  "mirage" { build & >= "4.9.0" & < "4.10.0" }
  "mirage-bootvar" { ?monorepo & >= "1.0.0" & < "2.0.0" }
  "mirage-crypto-rng-mirage" { ?monorepo & >= "2.0.0" & < "3.0.0" }
  "mirage-logs" { ?monorepo & >= "3.0.0" & < "4.0.0" }
  "mirage-mtime" { ?monorepo & >= "5.0.0" & < "6.0.0" }
  "mirage-ptime" { ?monorepo & >= "5.0.0" & < "6.0.0" }
  "mirage-runtime" { ?monorepo & >= "4.9.0" & < "4.10.0" }
  "mirage-sleep" { ?monorepo & >= "4.0.0" & < "5.0.0" }
  "mirage-unix" { ?monorepo & >= "5.0.0" & < "6.0.0" }
  "opam-monorepo" { build & >= "0.3.2" }

Query files
  $ ./config.exe query files
  Successfully configured the unikernel. Now run 'make' (or more fine-grained steps: 'make all', 'make depends', or 'make lock').
  main.ml

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
  	@echo "The lock file has been generated. Run 'make pull' to retrieve the sources, or 'make install-switch' to install the host dependencies."
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  	@echo "The sources have been pulled to the duniverse folder. Run 'make build' to build the unikernel."
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes
  	@$(MAKE) -s depext-lockfile
  	@echo "The dependencies have been installed. Run 'make build' to build the unikernel."
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	dune build --profile release --root . $(BUILD_DIR)dist
  	@echo "Your unikernel binary is now ready in $(BUILD_DIR)dist/noop"
  	@echo "Execute the binary using solo5-hvt, solo5-spt, xl, ..."
  
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
  	@echo "The lock file has been generated. Run 'make pull' to retrieve the sources, or 'make install-switch' to install the host dependencies."
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  	@echo "The sources have been pulled to the duniverse folder. Run 'make build' to build the unikernel."
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes --no-depexts
  	@echo "The dependencies have been installed. Run 'make build' to build the unikernel."
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	dune build --profile release --root . $(BUILD_DIR)dist
  	@echo "Your unikernel binary is now ready in $(BUILD_DIR)dist/noop"
  	@echo "Execute the binary using solo5-hvt, solo5-spt, xl, ..."
  
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
  	@echo "The lock file has been generated. Run 'make pull' to retrieve the sources, or 'make install-switch' to install the host dependencies."
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo dependencies in the duniverse folder"
  	@env OPAMVAR_monorepo="opam-monorepo" $(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  	@echo "The sources have been pulled to the duniverse folder. Run 'make build' to build the unikernel."
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@echo " ↳ opam install switch dependencies"
  	@$(OPAM) install $< --deps-only --yes
  	@$(MAKE) -s depext-lockfile
  	@echo "The dependencies have been installed. Run 'make build' to build the unikernel."
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	dune build --profile release --root . $(BUILD_DIR)dist
  	@echo "Your unikernel binary is now ready in $(BUILD_DIR)dist/noop"
  	@echo "Execute the binary using solo5-hvt, solo5-spt, xl, ..."
  
  clean::
  	mirage clean
  

Query version
  $ ./config.exe query --version
  %%VERSION%%

Query unikernel dune
  $ ./config.exe query dune.build
  Successfully configured the unikernel. Now run 'make' (or more fine-grained steps: 'make all', 'make depends', or 'make lock').
  (copy_files# ./mirage/main.ml)
  
  (rule
   (target noop)
   (enabled_if (= %{context_name} "default"))
   (deps main.exe)
   (action
    (copy main.exe %{target})))
  
  (executable
   (name main)
   (libraries cmdliner-stdlib duration lwt mirage-bootvar mirage-bootvar.unix
     mirage-crypto-rng-mirage mirage-logs mirage-mtime mirage-mtime.unix
     mirage-ptime mirage-ptime.unix mirage-runtime mirage-sleep
     mirage-sleep.unix mirage-unix)
   (link_flags (-thread))
   (modules (:standard \ config))
   (flags :standard -w -70)
   (enabled_if (= %{context_name} "default"))
  )

Query configuration dune
  $ ./config.exe query dune.config
  (data_only_dirs duniverse dist)
  
  (executable
   (name config)
   (modules config)
   (flags :standard -warn-error -A)
   (libraries mirage))

Query dune-project
  $ ./config.exe query dune-project --target unix
  (lang dune 2.9)
  
  (name noop-unix)
  
  (implicit_transitive_deps true)

Query dune-workspace
  $ ./config.exe query dune-workspace
  (lang dune 2.9)
  
  (context (default))

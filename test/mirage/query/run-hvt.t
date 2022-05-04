  $ export MIRAGE_DEFAULT_TARGET unix

Query opam file
  $ ./config.exe query --target hvt opam
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
    "lwt" { switch != "" }
    "mirage" { build & >= "4.1.0" & < "4.2.0" }
    "mirage-bootvar-solo5" { switch != "" & >= "0.6.0" & < "0.7.0" }
    "mirage-clock-solo5" { switch != "" & >= "4.2.0" & < "5.0.0" }
    "mirage-logs" { switch != "" & >= "1.2.0" & < "2.0.0" }
    "mirage-runtime" { switch != "" & >= "4.1.0" & < "4.2.0" }
    "mirage-solo5" { switch != "" & >= "0.8.0" & < "0.9.0" }
    "ocaml" { build & >= "4.08.0" }
    "ocaml-solo5" { build & >= "0.8.0" }
    "opam-monorepo" { build & >= "0.2.6" }
  ]
  
  x-opam-monorepo-opam-provided: ["mirage"
  "ocaml""ocaml-solo5"
  "opam-monorepo"]
  


Query packages
  $ ./config.exe query --target hvt packages
  "lwt" { switch != "" }
  "mirage" { build & >= "4.1.0" & < "4.2.0" }
  "mirage-bootvar-solo5" { switch != "" & >= "0.6.0" & < "0.7.0" }
  "mirage-clock-solo5" { switch != "" & >= "4.2.0" & < "5.0.0" }
  "mirage-logs" { switch != "" & >= "1.2.0" & < "2.0.0" }
  "mirage-runtime" { switch != "" & >= "4.1.0" & < "4.2.0" }
  "mirage-solo5" { switch != "" & >= "0.8.0" & < "0.9.0" }
  "ocaml" { build & >= "4.08.0" }
  "ocaml-solo5" { build & >= "0.8.0" }
  "opam-monorepo" { build & >= "0.2.6" }

Query files
  $ ./config.exe query --target hvt files
  key_gen.ml main.ml manifest.json manifest.ml

Query Makefile
  $ ./config.exe query --target hvt Makefile
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop-hvt
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
  
  
  
  depext-lockfile: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	echo " ↳ install external dependencies for monorepo"
  	$(OPAM) monorepo depext -y -l $<
  
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --require-cross-compile --build-only $(UNIKERNEL_NAME) -l $@ --ocaml-version $(shell ocamlc --version); (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  lock::
  	@$(MAKE) -B $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo rependencies in the duniverse folder"
  	@$(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@echo " ↳ opam install switch dependencies"
  	@env OPAMVAR_switch="" $(OPAM) install $< --deps-only --yes
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
  $ ./config.exe query --target hvt Makefile --no-depext
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop-hvt
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
  
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --require-cross-compile --build-only $(UNIKERNEL_NAME) -l $@ --ocaml-version $(shell ocamlc --version); (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  lock::
  	@$(MAKE) -B $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo rependencies in the duniverse folder"
  	@$(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@echo " ↳ opam install switch dependencies"
  	@env OPAMVAR_switch="" $(OPAM) install $< --deps-only --yes --no-depexts
  
  depends depend::
  	@$(MAKE) --no-print-directory lock
  	@$(MAKE) --no-print-directory install-switch
  	@$(MAKE) --no-print-directory pull
  
  build::
  	mirage build
  
  clean::
  	mirage clean
  

Query Makefile with depext
  $ ./config.exe query --target hvt Makefile --depext
  -include Makefile.user
  BUILD_DIR = ./
  MIRAGE_DIR = ./mirage
  UNIKERNEL_NAME = noop-hvt
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
  
  
  
  depext-lockfile: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	echo " ↳ install external dependencies for monorepo"
  	$(OPAM) monorepo depext -y -l $<
  
  
  $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@$(MAKE) -s repo-add
  	@echo " ↳ generate lockfile for monorepo dependencies"
  	@$(OPAM) monorepo lock --require-cross-compile --build-only $(UNIKERNEL_NAME) -l $@ --ocaml-version $(shell ocamlc --version); (ret=$$?; $(MAKE) -s repo-rm && exit $$ret)
  
  lock::
  	@$(MAKE) -B $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  
  pull:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam.locked
  	@echo " ↳ fetch monorepo rependencies in the duniverse folder"
  	@$(OPAM) monorepo pull -l $< -r $(abspath $(BUILD_DIR))
  
  install-switch:: $(MIRAGE_DIR)/$(UNIKERNEL_NAME).opam
  	@echo " ↳ opam install switch dependencies"
  	@env OPAMVAR_switch="" $(OPAM) install $< --deps-only --yes
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
  $ ./config.exe query --target hvt --version
  %%VERSION%%

Query unikernel dune
  $ ./config.exe query --target hvt dune.build
  (copy_files ./config/*)
  
  (executable
   (enabled_if (= %{context_name} "solo5"))
   (name main)
   (modes (native exe))
   (libraries lwt mirage-bootvar-solo5 mirage-clock-solo5 mirage-logs
     mirage-runtime mirage-solo5)
   (link_flags :standard -w -70 -cclib "-z solo5-abi=hvt")
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
   (enabled_if (= %{context_name} "solo5"))
   (deps main.exe)
   (action
    (copy main.exe %{target})))

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
    (name solo5)
    (host default)
    (toolchain solo5)
    (disable_dynamically_linked_foreign_archives true)
    ))

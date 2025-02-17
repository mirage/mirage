Query unikernel dune
  $ ./config_noop.exe query dune.build
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

Query dist dune
  $ ./config_noop.exe query dune.dist
  (rule
   (mode (promote (until-clean)))
   (target noop)
   (enabled_if (= %{context_name} "default"))
   (action
    (copy ../noop %{target}))
  )

Query makefile
  $ ./config_noop.exe query Makefile --target unix
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
  
...

Query dune-project
  $ ./config_noop.exe query dune-project --target unix
  (lang dune 2.9)
  
  (name noop-unix)
  
  (implicit_transitive_deps true)

Query unikernel dune (hvt)
  $ ./config_noop.exe query --target hvt dune.build
  Successfully configured the unikernel. Now run 'make' (or more fine-grained steps: 'make all', 'make depends', or 'make lock').
  (copy_files# ./mirage/main.ml)
  
  (copy_files ./mirage/manifest.json)
  
  (copy_files# ./mirage/manifest.ml)
  
  (executable
   (enabled_if (= %{context_name} "solo5"))
   (name main)
   (modes (native exe))
   (libraries cmdliner-stdlib duration lwt mirage-bootvar mirage-bootvar.solo5
     mirage-crypto-rng-mirage mirage-logs mirage-mtime mirage-mtime.solo5
     mirage-ptime mirage-ptime.solo5 mirage-runtime mirage-sleep
     mirage-sleep.solo5 mirage-solo5)
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

Query dist dune (hvt)
  $ ./config_noop.exe query --target hvt dune.dist
  (rule
   (mode (promote (until-clean)))
   (target noop.hvt)
   (enabled_if (= %{context_name} "solo5"))
   (action
    (copy ../noop.hvt %{target}))
  )

PREFIX ?= $(HOME)/mir-inst
export PREFIX

.PHONY: bootstrap
bootstrap:
	@cd ocaml && $(MAKE) && $(MAKE) install
	mkdir -p $(PREFIX)
	tar -zxf ocaml/install.tgz -C $(PREFIX)
	cd ocaml-libs && $(MAKE)
	cd ocamljs && $(MAKE)
	echo You should now add $(PREFIX) to your PATH variable

tools:
	@cd ocamldsort && ./configure --prefix=$(PREFIX)
	@cd mpl && $(MAKE) && $(MAKE) install
	@cd ocamldsort && $(MAKE) && $(MAKE) install
	@cd crunch && $(MAKE) && $(MAKE) install
	@cd mir && $(MAKE) install
	@cd ocamlpack && $(MAKE) install

rebootstrap:
	@$(MAKE) clean
	@rm -rf $(PREFIX)/lib/ocaml/site-lib
	@$(MAKE) bootstrap

.PHONY: clean
clean:
	@cd ocaml && $(MAKE) clean
	@cd ocaml-libs && $(MAKE) clean
	@cd ocamljs && $(MAKE) clean
	@cd mpl && $(MAKE) clean
	@cd ocamldsort && $(MAKE) clean || true
	@cd crunch && $(MAKE) clean
	@cd mir && $(MAKE) clean
	@cd ocamlpack && $(MAKE) clean

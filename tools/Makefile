PREFIX ?= $(HOME)/mir-inst
export PREFIX

.PHONY: bootstrap
bootstrap:
	@cd ocaml && $(MAKE) && $(MAKE) install
	mkdir -p $(PREFIX)
	tar -zxf ocaml/install.tgz -C $(PREFIX)
	@cd ocaml-libs && $(MAKE)
	@cd ocamljs && $(MAKE)

tools:
	@cd ocamldsort && ./configure --prefix=$(PREFIX)
	@cd mpl && $(MAKE) && $(MAKE) install
	@cd ocamldsort && $(MAKE) && $(MAKE) install
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
	@cd mir && $(MAKE) clean
	@cd ocamlpack && $(MAKE) clean

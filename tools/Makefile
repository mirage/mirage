PREFIX ?= $(HOME)/mir-inst
export PREFIX

PATH:=$(PREFIX)/bin:$(PATH)
export PATH

.PHONY: bootstrap
bootstrap:
	if [ ! -e $(PREFIX)/bin/ocaml ]; then cd ocaml && \
	  $(MAKE) && $(MAKE) install; mkdir -p $(PREFIX); \
	  tar -zxf install.tgz -C $(PREFIX); fi
	cd ocaml-libs && $(MAKE)
	echo You should now add $(PREFIX)/bin to the front of your PATH variable

tools:
	@cd mpl && $(MAKE) && $(MAKE) install
	@cd crunch && $(MAKE) && $(MAKE) install
	@cd mir && $(MAKE) install

rebootstrap:
	@$(MAKE) clean
	@rm -rf $(PREFIX)/lib/ocaml/site-lib
	@$(MAKE) bootstrap

.PHONY: clean
clean:
	@cd ocaml && $(MAKE) clean
	@cd ocaml-libs && $(MAKE) clean
	@cd mpl && $(MAKE) clean
	@cd crunch && $(MAKE) clean
	@cd mir && $(MAKE) clean

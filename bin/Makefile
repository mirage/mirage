ROOTDIR = ..
include $(ROOTDIR)/mk/ocaml.mk

PREFIX ?= /usr/local

.PHONY: install
install: mir.in
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	sed -e 's/@OCAMLOPT_FLAGS@/$(OCAMLOPT_FLAGS)/g' \
	    -e 's/@OS@/$(OS)/g' \
	    -e 's/@OCAML_CLIBS@/$(OCAML_CLIBS)/g' < mir.in > $(DESTDIR)$(PREFIX)/bin/mir
	chmod 755 $(DESTDIR)$(PREFIX)/bin/mir

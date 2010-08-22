ROOTDIR = ../..
include $(ROOTDIR)/mk/ocaml.mk

PREFIX ?= /usr/local/mirage

.PHONY: install
install: mir.in
	mkdir -p $(PREFIX)/bin
	sed -e 's/@OCAMLOPT_FLAGS@/$(OCAMLOPT_FLAGS)/g' \
	    -e 's/@OS@/$(OS)/g' -e 's,@PREFIX@,$(PREFIX),g' \
	    -e 's/@OCAML_CLIBS@/$(OCAML_CLIBS)/g' < mir.in > $(PREFIX)/bin/mir
	chmod 755 $(PREFIX)/bin/mir

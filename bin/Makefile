ROOTDIR = ..
include $(ROOTDIR)/mk/ocaml.mk

PREFIX ?= /usr/local

.PHONY: install
install: mir.in
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	sed -e 's/@OCAMLOPT_FLAGS@/$(OCAMLOPT_FLAGS)/g' < mir.in > $(DESTDIR)$(PREFIX)/bin/mir

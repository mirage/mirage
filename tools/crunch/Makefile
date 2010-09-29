OCAMLMAKEFILE=../OCamlMakefile

PREFIX ?= /usr/local/mirage
SOURCES=custom_unix_stubs.c crunch.ml
RESULT=mlcrunch
LIBS=unix
ANNOTATE=yes

.PHONY: build
build: nc
	@ :

.PHONY: install
install: nc
	mkdir -p $(PREFIX)/bin
	cp $(RESULT) $(PREFIX)/bin/$(RESULT)
	chmod 755 $(PREFIX)/bin/$(RESULT)

include $(OCAMLMAKEFILE)

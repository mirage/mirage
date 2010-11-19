OCAMLMAKEFILE=../OCamlMakefile

PREFIX ?= ~/mir-inst
SOURCES=unix_stubs.c mir.ml 
RESULT=mir
ANNOTATE=yes

.PHONY: build
build: nc
	@ :

.PHONY: install
install: nc
	mkdir -p $(PREFIX)/bin
	cp mir $(PREFIX)/bin/mir
	chmod 755 $(PREFIX)/bin/mir

include $(OCAMLMAKEFILE)

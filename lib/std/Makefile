PREFIX ?= ~/mir-inst/lib

.PHONY: all lib syntax clean install
all: syntax lib
	@ :

syntax:
	ocamlbuild $(JOBS) -use-ocamlfind syntax.otarget

lib: syntax
	ocamlbuild $(JOBS) -X syntax lib.otarget
	ocamlbuild $(JOBS) -X syntax lib_byte.otarget

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/std
install:
	mkdir -p $(TARGETDIR)/lib $(TARGETDIR)/syntax
	cp _build/lib/*.cmi _build/lib/*.cmxa _build/lib/*.cma _build/lib/*.a $(TARGETDIR)/lib
	cp _build/syntax/pa_*.cma $(TARGETDIR)/syntax

clean:
	ocamlbuild -clean

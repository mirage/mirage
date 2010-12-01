PREFIX ?= _build/root

.PHONY: all clean install
all:
	ocamlbuild -use-ocamlfind syntax.otarget
	ocamlbuild all.otarget

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/std
install:
	mkdir -p $(TARGETDIR)/lib $(TARGETDIR)/syntax
	cp _build/lib/*.cmi _build/lib/*.cmxa _build/lib/*.a $(TARGETDIR)/lib
	cp _build/syntax/pa_lwt.cmo $(TARGETDIR)/syntax

clean:
	ocamlbuild -clean

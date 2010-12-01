PREFIX ?= _build/root

.PHONY: all lwt_syntax std dyntype_syntax clean install
all: lwt_syntax std dyntype_syntax
	@ :

lwt_syntax:
	ocamlbuild -use-ocamlfind lwt_syntax.otarget

std: lwt_syntax
	ocamlbuild all.otarget

syntax/dyntype.ml:
	@cd syntax && ln -nfs ../lib/dyntype.ml .

dyntype_syntax: syntax/dyntype.ml
	ocamlbuild -use-ocamlfind dyntype_syntax.otarget

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/std
install:
	mkdir -p $(TARGETDIR)/lib $(TARGETDIR)/syntax
	cp _build/lib/*.cmi _build/lib/*.cmxa _build/lib/*.a $(TARGETDIR)/lib
	cp _build/syntax/pa_lwt.cmo $(TARGETDIR)/syntax
	cp _build/syntax/pa_type_conv.cmo $(TARGETDIR)/syntax
	cp _build/syntax/dyntype.cmo $(TARGETDIR)/syntax
	cp _build/syntax/pa_dyntype.cmo $(TARGETDIR)/syntax

clean:
	rm -f syntax/dyntype.ml
	ocamlbuild -clean

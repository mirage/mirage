PREFIX ?= ~/mir-inst/lib

.PHONY: all lib syntax clean

all: syntax lib
	@ :

syntax: syntax/html/xml.ml
	ocamlbuild syntax.otarget

syntax/html/xml.ml:
	@cd syntax/html && ln -nsf ../../lib/xml.ml .

lib: syntax
	ocamlbuild lib.otarget

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/cow

install:
	mkdir -p $(TARGETDIR)/lib $(TARGETDIR)/syntax
	cp _build/lib/*.cmi _build/lib/*.cmx _build/lib/*.o $(TARGETDIR)/lib
	cp _build/syntax/pa_html.cmo $(TARGETDIR)/syntax

clean:
	rm -f syntax/html/xml.ml
	ocamlbuild -clean

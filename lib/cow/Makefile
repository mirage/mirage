PREFIX ?= ~/mir-inst/lib

.PHONY: all lib syntax clean

all: syntax lib
	@ :

syntax: syntax/xml/xml.ml syntax/html/xhtml.ml
	ocamlbuild -I syntax syntax.otarget

syntax/xml/xml.ml:
	@cd syntax/xml && ln -nsf ../../lib/xml.ml .

syntax/html/xhtml.ml:
	@cd syntax/html && ln -nsf ../../lib/xhtml.ml .

lib: syntax
	ocamlbuild lib.otarget

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/cow

install:
	mkdir -p $(TARGETDIR)/lib $(TARGETDIR)/syntax
	cp _build/lib/*.cmi _build/lib/*.cmx _build/lib/*.o $(TARGETDIR)/lib
	cp _build/syntax/pa_html.cmo $(TARGETDIR)/syntax
	cp _build/syntax/pa_xml.cmo $(TARGETDIR)/syntax

clean:
	rm -f syntax/xml/xml.ml syntax/html/xhtml.ml
	ocamlbuild -clean

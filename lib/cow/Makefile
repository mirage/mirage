PREFIX ?= ~/mir-inst

.PHONY: all lib syntax clean

all: syntax lib
	@ :

syntax: syntax/xml/xml.ml syntax/html/xhtml.ml syntax/json/json.ml
	ocamlbuild -I syntax syntax.otarget

syntax/xml/xml.ml:
	@cd syntax/xml && ln -nsf ../../lib/xml.ml .

syntax/html/xhtml.ml:
	@cd syntax/html && ln -nsf ../../lib/xhtml.ml .

syntax/json/json.ml:
	@cd syntax/json && ln -nsf ../../lib/json.ml .

lib: syntax
	ocamlbuild lib.otarget

test: syntax lib
	rm -rf tests/_build
	cd tests && MIRAGELIB=$(DESTDIR)/$(PREFIX)/mirage && mir json/main.bin
	tests/_build/json/main.bin

test_exp: syntax lib
	rm -f  _build/tests/json/*_exp.ml
	ocamlbuild tests_exp.otarget
	_build/tests/json/main_exp.native

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/cow

install:
	mkdir -p $(TARGETDIR)/lib $(TARGETDIR)/syntax
	cp _build/lib/*.cmi _build/lib/*.cmx _build/lib/*.o $(TARGETDIR)/lib
	cp _build/syntax/pa_cow.cmo $(TARGETDIR)/syntax

clean:
	rm -f syntax/xml/xml.ml syntax/html/xhtml.ml syntax/json/json.ml
	cd tests && ocamlbuild -clean && rm myocamlbuild.ml
	ocamlbuild -clean

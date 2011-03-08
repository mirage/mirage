PREFIX ?= ~/mir-inst

.PHONY: all lib syntax clean

PREFIX ?= _build/root

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_BUILD=xen-direct
else
XEN_BUILD=
endif

all: syntax unix-direct unix-socket $(XEN_BUILD) node-socket
	@ :

syntax: syntax/xml/xml.ml syntax/html/xhtml.ml syntax/json/json.ml
	ocamlbuild $(JOBS) -I syntax syntax.otarget

syntax/xml/xml.ml:
	@cd syntax/xml && ln -nsf ../../lib/xml.ml .

syntax/html/xhtml.ml:
	@cd syntax/html && ln -nsf ../../lib/xhtml.ml .

syntax/json/json.ml:
	@cd syntax/json && ln -nsf ../../lib/json.ml .

unix-%: 
	MIRAGEOS=unix MIRAGEFLOW=$* ocamlbuild $(JOBS) -I syntax syntax.otarget
	MIRAGEOS=unix MIRAGEFLOW=$* ocamlbuild $(JOBS) lib/cow.cmxa

xen-%: syntax
	MIRAGEOS=xen MIRAGEFLOW=$* ocamlbuild $(JOBS) -I syntax syntax.otarget
	MIRAGEOS=xen MIRAGEFLOW=$* ocamlbuild $(JOBS) lib/cow.cmxa

node-%:
	MIRAGEOS=node MIRAGEFLOW=$* ocamlbuild $(JOBS) -I syntax syntax.otarget
	MIRAGEOS=node MIRAGEFLOW=$* ocamlbuild $(JOBS) lib/cow.cma

test: syntax lib
	rm -rf tests/_build
	cd tests && MIRAGELIB=$(DESTDIR)/$(PREFIX)/mirage && make
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
	cd tests && make clean
	ocamlbuild -clean

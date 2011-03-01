PREFIX ?= ~/mir-inst/lib

.PHONY: all lib syntax clean install
all: lib syntax
	@ :

lib:
	ocamlbuild $(JOBS) lib/dyntype.cmx

syntax/dyntype.ml:
	@cd syntax && ln -nfs ../lib/dyntype.ml .

syntax: syntax/dyntype.ml
	ocamlbuild $(JOBS) syntax.otarget

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/dyntype
install:
	mkdir -p $(TARGETDIR)/lib $(TARGETDIR)/syntax
	cp _build/lib/*.cmi _build/lib/*.cmx _build/lib/*.o $(TARGETDIR)/lib
	cp _build/syntax/*.cmi _build/syntax/*.cmo $(TARGETDIR)/syntax

clean:
	rm -f syntax/dyntype.ml
	ocamlbuild -clean

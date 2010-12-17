.PHONY: all install clean

all: static.ml
	ocamlbuild lib/debugger.cmx

static.ml:
	mlcrunch static/ > lib/static.ml

clean:
	ocamlbuild -clean
	rm -f lib/static.ml

PREFIX ?= ~/mir-inst
TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/debugger

install:
	mkdir -p $(TARGETDIR)/lib
	cp _build/lib/*.cmi _build/lib/*.cmx _build/lib/*.o $(TARGETDIR)/lib
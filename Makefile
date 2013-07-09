PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

all: _build/lib/mirari.native

_build/.stamp:
	rm -rf _build
	mkdir -p _build/lib
	@touch $@
	
_build/lib/mirari.native: _build/.stamp
	ocamlbuild -use-ocamlfind -pkg cmdliner -pkg unix -pkg tuntap -pkg fd-send-recv lib/mirari.native

.PHONY: clean
clean:
	rm -rf _build

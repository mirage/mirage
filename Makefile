PREFIX ?= /usr/local
VERSION = 0.9.6
PKGS    = cmdliner,unix,tuntap,fd-send-recv,cohttp.mirage,mirage-types

BUILD   = ocamlbuild -use-ocamlfind -pkgs $(PKGS)

all: _build/lib/mirari.native

lib/path_generated.ml:
	echo let project_version=\"$(VERSION)\" > $@

_build/.stamp:
	rm -rf _build
	mkdir -p _build/lib
	@touch $@

_build/lib/mirari.native: _build/.stamp lib/path_generated.ml
	$(BUILD) lib/main.native

install:
	cp _build/lib/main.native $(PREFIX)/bin/mirari

uninstall:
	rm $(PREFIX)/bin/mirari

.PHONY: clean
clean:
	rm -rf _build lib/path_generated.ml

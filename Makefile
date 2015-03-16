PREFIX ?= /usr/local
NAME    = mirage
VERSION = $(shell grep 'Version:' _oasis | sed 's/Version: *//')
VFILE   = lib/mirage_version.ml

CONF_FLAGS ?=


.PHONY: all clean install build
all: build

setup.bin: setup.ml
	ocamlopt.opt -o $@ $< || ocamlopt -o $@ $< || ocamlc -o $@ $<
	rm -f setup.cmx setup.cmi setup.o setup.cmo

setup.data: setup.bin
	./setup.bin -configure $(CONF_FLAGS) --prefix $(PREFIX)

build-types:
	./build

install-types:
	./build true

build: setup.data setup.bin $(VFILE)
	./setup.bin -build -classic-display

doc: setup.data setup.bin
	./setup.bin -doc

install: setup.bin
	./setup.bin -install

uninstall: setup.bin
	./setup.bin -uninstall

test: setup.bin build
	./setup.bin -test

fulltest: setup.bin build
	./setup.bin -test

reinstall: setup.bin
	ocamlfind remove $(NAME) || true
	./setup.bin -reinstall

clean:
	ocamlbuild -clean
	rm -f setup.data setup.log setup.bin $(VFILE)

$(VFILE): _oasis
	echo "let current = \"$(VERSION)\"" > $@

update-doc: doc
	rm -f gh-pages/*.html
	cd gh-pages && cp ../mirage.docdir/*.html .
	cd gh-pages && git add * && git commit -a -m "Update docs"
	cd gh-pages && git push

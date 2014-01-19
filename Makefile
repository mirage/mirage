.PHONY: all clean install build
all: build test doc

PREFIX ?= /usr/local
NAME=mirage
CONF_FLAGS ?=

setup.bin: setup.ml
	ocamlopt.opt -o $@ $< || ocamlopt -o $@ $< || ocamlc -o $@ $<
	rm -f setup.cmx setup.cmi setup.o setup.cmo

setup.data: setup.bin
	./setup.bin -configure $(CONF_FLAGS) --prefix $(PREFIX)

build-types:
	./build

install-types:
	./build true

build: setup.data setup.bin
	./setup.bin -build -classic-display

doc: setup.data setup.bin
	./setup.bin -doc

install: setup.bin
	./setup.bin -install

test: setup.bin build
	./setup.bin -test

fulltest: setup.bin build
	./setup.bin -test

reinstall: setup.bin
	ocamlfind remove $(NAME) || true
	./setup.bin -reinstall

clean:
	ocamlbuild -clean
	rm -f setup.data setup.log setup.bin

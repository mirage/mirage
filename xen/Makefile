.PHONY: all _config build install uninstall doc clean

EXTRA=runtime/dietlibc/libdiet.a runtime/libm/libm.a runtime/kernel/libxen.a runtime/kernel/libxencaml.a runtime/ocaml/libocaml.a runtime/kernel/x86_64.o runtime/kernel/longjmp.o runtime/kernel/mirage-x86_64.lds

OCAMLFIND ?= ocamlfind

XEN_LIB = $(shell ocamlfind printconf path)/mirage-xen

all: build

_config:
	./cmd configure xen

build: _config
	./cmd build
	ocamlbuild $(EXTRA)

install:
	./cmd install
	mkdir -p $(XEN_LIB)
	for l in $(EXTRA); do cp _build/$$l $(XEN_LIB); done

uninstall:
	./cmd uninstall

doc: _config
	./cmd doc

clean:
	./cmd clean

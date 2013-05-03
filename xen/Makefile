.PHONY: all clean depend install

EXTRA=runtime/dietlibc/libdiet.a runtime/libm/libm.a runtime/kernel/libxen.a runtime/kernel/libxencaml.a runtime/ocaml/libocaml.a runtime/kernel/x86_64.o runtime/kernel/longjmp.o runtime/kernel/mirage-x86_64.lds

OCAMLFIND ?= ocamlfind

XEN_LIB = $(shell ocamlfind printconf path)/mirage-xen

all: 
	./cmd configure xen
	./cmd build
	ocamlbuild $(EXTRA)

install:
	./cmd install
	mkdir -p $(XEN_LIB)
	for l in $(EXTRA); do cp _build/$$l $(XEN_LIB); done

uninstall:
	./cmd uninstall

clean:
	./cmd clean

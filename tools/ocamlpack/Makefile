OCAMLMAKEFILE = ../OCamlMakefile

SOURCES=ocamlpack.ml
RESULT=ocamlpack
ANNOTATE=yes
LIBS=str

.PHONY: all
all: nc
	@ :

.PHONY: install
install: nc
	mkdir -p $(PREFIX)/bin
	cp $(RESULT) $(PREFIX)/bin/$(RESULT)
	chmod 755 $(PREFIX)/bin/$(RESULT)

include $(OCAMLMAKEFILE)

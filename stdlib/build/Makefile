SOURCES ?=
RESULT ?= app
OBJDIR ?= $(CURDIR)

OCAMLOPT ?= ocamlopt.opt
OCAMLDSORT ?= ocamldsort
STDLIB = $(CURDIR)/../src
OCAMLDIR = $(shell ocamlc -where)
STDLIB_ML=$(wildcard $(STDLIB)/*.ml $(STDLIB)/*.mli)

.PHONY: build
$(RESULT).o: pervasives.ml
	$(OCAMLOPT) -c -nopervasives -nostdlib pervasives.mli pervasives.ml
	$(OCAMLOPT) -c -nopervasives -nostdlib $(shell $(OCAMLDSORT) -mli *.mli)
	$(OCAMLOPT) -nopervasives -nostdlib $(shell $(OCAMLDSORT) *.ml) -output-obj -o $@

pervasives.ml:
	@for i in $(STDLIB_ML); do ln -nfs $$i; done
	@for i in $(SOURCES); do ln -nfs $$i; done

.PHONY: clean
clean:
	rm -f *.cmx *.cmi *.a *.o *.cmo $(RESULT)
	find . -type l -exec rm -f {} \;

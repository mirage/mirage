OCAMLOPT ?= ocamlopt.opt
OCAMLDEP ?= ocamldep.opt
OCAMLDSORT ?= ocamldsort.opt

CORE=pervasives.ml
ALL=$(wildcard *.ml)
LIBS=$(filter-out $(CORE),$(ALL)) 

.PHONY: build
build: pervasives.cmx
	$(OCAMLOPT) -c -nostdlib $(shell $(OCAMLDSORT) -mli *.ml *.mli)

pervasives.cmi: pervasives.mli
	$(OCAMLOPT) -c -nostdlib -nopervasives $<

pervasives.cmx: pervasives.ml pervasives.cmi
	$(OCAMLOPT) -c -nostdlib -nopervasives $<

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi

OCAMLOPT ?= ocamlopt.opt

LIBS = pervasives

.PHONY: all
all: $(LIBS:%=%.cmx)
	@ :

%.cmx: %.ml
	$(OCAMLOPT) -c -nopervasives $<

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o

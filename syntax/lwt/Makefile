OCAMLC ?= ocamlc
CAMLP4ORF ?= camlp4orf

.PHONY: all clean
all: pa_lwt.cmo
	@ :

%.cmi: %.mli
	$(OCAMLC) -I +camlp4 -c -pp camlp4of $<

%.cmo: %.ml %.cmi
	$(OCAMLC) -I +camlp4 -c -pp camlp4of $<

.PRECIOUS: %.cmi

.PHONY: clean
clean:
	rm -f *.cmi *.cmo *.cma


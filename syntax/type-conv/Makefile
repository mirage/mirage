OCAMLC ?= ocamlc

.PHONY: all clean
all: pa_type_conv.cmo
	@ :

%.cmi: %.mli
	$(OCAMLC) -I +camlp4 -c -pp camlp4orf $<

%.cmo: %.ml %.cmi
	$(OCAMLC) -I +camlp4 -c -pp camlp4orf $<

.PRECIOUS: %.cmi

.PHONY: clean
clean:
	rm -f *.cmi *.cmo *.cma


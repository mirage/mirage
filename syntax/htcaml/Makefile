OCAMLC ?= ocamlc

SOURCES = htcaml_ast htcaml_parser htcaml_quotations htcaml_printer
CMOS = $(SOURCES:%=%.cmo)

.PHONY: all clean
all: htcaml.cma
	@ :

%.cmi: %.mli
	$(OCAMLC) -I +camlp4 -c -pp camlp4of $<

%.cmo: %.ml %.cmi
	$(OCAMLC) -I +camlp4 -c -pp camlp4of $<

htcaml.cma: $(CMOS)
	$(OCAMLC) -a -o $@ $^
.PRECIOUS: %.cmi

.PHONY: clean
clean:
	rm -f *.cmi *.cmo *.cma


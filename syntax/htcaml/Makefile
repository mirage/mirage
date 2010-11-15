OCAMLC ?= ocamlc
OCAMLYACC ?= ocamlyacc
OCAMLLEX ?= ocamllex

SOURCES = htcaml_ast htcaml_location htcaml_parser htcaml_lexer htcaml_quotations htcaml_printer pa_htcaml
CMOS = $(SOURCES:%=%.cmo)

.PHONY: all clean
all: htcaml.cma
	@ :

htcaml_location.cmo: htcaml_location.ml
	$(OCAMLC) -I +camlp4 -c -pp camlp4of $<	

pa_htcaml.cmo: pa_htcaml.ml
	$(OCAMLC) -I +camlp4 -I ../type-conv -I ../dyntype -c -pp camlp4orf $<

htcaml_lexer.cmo: htcaml_lexer.mll
	$(OCAMLLEX) $<
	$(OCAMLC) -I +camlp4 -c -pp camlp4of htcaml_lexer.ml

htcaml_parser.ml htcaml_parser.mli: htcaml_parser.mly
	$(OCAMLYACC) $<

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


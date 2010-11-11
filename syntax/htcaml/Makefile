OCAMLC ?= ocamlfind ocamlc

SOURCES = xhtml htcaml_ast htcaml_location htcaml_parser  htcaml_quotations htcaml_printer pa_htcaml
CMOS = $(SOURCES:%=%.cmo)

INCLS = -I +camlp4 \
        -I ../type-conv \
        -I ../dyntype

.PHONY: all clean xml
all: htcaml.cma
	@ :

htcaml_location.cmo: htcaml_location.ml
	$(OCAMLC) $(INCLS) -c -pp camlp4of $<	

xhtml.cmo: xhtml.ml
	$(OCAMLC) $(INCLS) -c -pp camlp4of $<	

pa_htcaml.cmo: pa_htcaml.ml
	$(OCAMLC) $(INCLS) -c -pp camlp4orf $<

%.cmi: %.mli
	$(OCAMLC) -package xmlm,str $(INCLS) $<

%.cmo: %.ml %.cmi
	$(OCAMLC) -linkall -linkpkg -package xmlm,str $(INCLS) -c -pp camlp4orf $<

htcaml.cma: $(CMOS)
	$(OCAMLC) -linkall -linkpkg -a -o $@ $^
.PRECIOUS: %.cmi

.PHONY: clean
clean:
	rm -f *.cmi *.cmo *.cma


OCAMLC ?= ocamlc
CAMLP4ORF ?= camlp4orf

.PHONY: all clean
all: pa_dyntype.cma
	@ :

SOURCES=value.ml p4_value.ml pa_value.ml type.ml p4_type.ml pa_type.ml
CMIS=value.cmi type.cmi
CMOS=$(patsubst %.ml,%.cmo,$(SOURCES))
INC=-I +camlp4 -I ../type-conv

pa_dyntype.cma: $(CMOS)
	@ :

%.cmi: %.mli
	$(OCAMLC) $(INC) -c -pp camlp4orf $<

%.cmo: %.ml $(CMIS)
	$(OCAMLC) $(INC) -c -pp camlp4orf $<

.PRECIOUS: %.cmi

.PHONY: clean
clean:
	rm -f *.cmi *.cmo *.cma

.PHONY: install
install:
	mkdir -p $(MIRAGE_ROOT)/syntax
	cp pa_mirage.cma $(MIRAGE_ROOT)/syntax/pa_mirage.cma

OCAMLC ?= ocamlc
CAMLP4OF ?= camlp4of
CAMLP4ORF ?= camlp4orf
MIRAGE_ROOT ?= $(PREFIX)/lib/ocaml/mirage

.PHONY: all clean
all: pa_mirage.cma
	@ :

lwt/%.cmo:
	cd lwt && $(MAKE)

type-conv/%.cmo:
	cd type-conv && $(MAKE)

dyntype/%.cmo:
	cd dyntype && $(MAKE)

htcaml/%.cma:
	cd htcaml && $(MAKE)

LWT_SOURCES=pa_lwt
TC_SOURCES=pa_type_conv
DYNTYPE_SOURCES=type value p4_helpers p4_type p4_value pa_type pa_value
SOURCES=$(LWT_SOURCES:%=lwt/%) $(TC_SOURCES:%=type-conv/%) $(DYNTYPE_SOURCES:%=dyntype/%)
pa_mirage.cma: $(SOURCES:%=%.cmo) htcaml/htcaml.cma
	$(OCAMLC) -a -o $@ $^

.PHONY: clean
clean:
	rm -f *.cmi *.cmo *.cma
	for i in lwt type-conv dyntype htcaml; do (cd $$i && $(MAKE) clean); done

.PHONY: install
install:
	mkdir -p $(MIRAGE_ROOT)/syntax
	cp pa_mirage.cma $(MIRAGE_ROOT)/syntax/pa_mirage.cma

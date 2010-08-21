OCAMLC ?= ocamlc
CAMLP4OF ?= camlp4of
MIRAGE_ROOT ?= $(PREFIX)/lib/ocaml/mirage

.PHONY: all clean
all: pa_mirage.cma
	@ :

pa_mirage.cma: pa_lwt.cmo
	$(OCAMLC) -a -o $@ $^

pa_lwt.cmi: pa_lwt.mli
	$(OCAMLC) -I +camlp4 -c -pp '$(CAMLP4OF)' $<

pa_lwt.cmo: pa_lwt.ml pa_lwt.cmi
	$(OCAMLC) -I +camlp4 -c -pp '$(CAMLP4OF)' $<

.PHONY: clean
clean:
	rm -f *.cmi *.cmo *.cma

.PHONY: install
install:
	mkdir -p $(MIRAGE_ROOT)
	cp pa_mirage.cma $(MIRAGE_ROOT)/pa_mirage.cma

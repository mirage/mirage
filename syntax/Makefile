OCAMLC ?= ocamlc
CAMLP4OF ?= camlp4of

.PHONY: all clean
all: pa_mirage.cma
	@ :

pa_mirage.cma: pa_lwt.cmo
	$(OCAMLC) -a -o $@ $^

pa_lwt.cmi: pa_lwt.mli
	$(OCAMLC) -I +camlp4 -c -pp '$(CAMLP4OF)' $<

pa_lwt.cmo: pa_lwt.ml pa_lwt.cmi
	$(OCAMLC) -I +camlp4 -c -pp '$(CAMLP4OF)' $<

clean:
	rm -f *.cmi *.cmo *.cma


OCAMLOPT ?= ocamlopt.opt
OCAMLDEP ?= ocamldep.opt
OCAMLDSORT ?= ocamldsort

.PHONY: build
build: stdlib.cmxa
	@ :

.mldeps:
	$(OCAMLDSORT) -mli *.ml *.mli > $@

.cmxdeps:
	$(OCAMLDSORT) -opt *.ml > $@

stdlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -nopervasives pervasives.mli pervasives.ml `cat .mldeps`
	$(OCAMLOPT) -a -o stdlib.cmxa `cat .cmxdeps`

pervasives.cmi: pervasives.mli
	$(OCAMLOPT) -c -nostdlib -nopervasives $<

pervasives.cmx: pervasives.ml pervasives.cmi
	$(OCAMLOPT) -c -nostdlib -nopervasives $<

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps

ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/stdlib
.PHONY: build
build: lwtlib.cmxa
	@ :

.mldeps: *.ml *.mli
	$(OCAMLDSORT) $(SYNTAX) -mli *.ml *.mli > $@

.cmxdeps: .mldeps
	$(OCAMLDSORT) $(SYNTAX) -opt *.ml > $@

lwtlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -annot -I $(STDLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -a -o $@ `cat .cmxdeps`

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a

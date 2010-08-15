ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
XSLIB=$(ROOTDIR)/lib/xen

.PHONY: build
build: netfrontlib.cmxa
	@ :

.mldeps: *.ml *.mli
	$(OCAMLDSORT) $(SYNTAX) -mli *.ml *.mli > $@

.cmxdeps: .mldeps
	$(OCAMLDSORT) $(SYNTAX) -opt *.ml > $@

netfrontlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -annot -I $(STDLIB) -I $(LWTLIB) -I $(XSLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -a -o $@ `cat .cmxdeps`

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a
	rm -rf ._d

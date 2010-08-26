ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/lib/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
MPLLIB=$(ROOTDIR)/lib/mpl
INCLUDES=-I $(STDLIB) -I $(LWTLIB) -I $(MPLLIB)

.PHONY: build
build: xen.cmx
	@ :

.mldeps: *.ml *.mli
	$(OCAMLDSORT) $(SYNTAX) -mli *.ml *.mli > $@

.cmxdeps: .mldeps
	$(OCAMLDSORT) $(SYNTAX) -opt *.ml > $@

xen.cmx: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -for-pack Xen -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -c -nostdlib -for-pack Xen -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -pack -o $@ `cat .cmxdeps`

.PHONY: i-%
i-%:
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) -i $*.ml

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a
	rm -rf ._d

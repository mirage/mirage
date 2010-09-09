ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk
OCAMLC   = ocamljs
OCAMLOPT = ocamljs

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/lib/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
MPLLIB=$(ROOTDIR)/lib/mpl
INCLUDES=-I $(STDLIB) -I $(LWTLIB) -I $(MPLLIB)

.PHONY: build
build: browser.cmjs
	@ :

.mldeps: *.ml *.mli
	$(OCAMLDSORT) $(SYNTAX) -mli *.ml *.mli > $@

.cmjsdeps: .mldeps
	$(OCAMLDSORT) $(SYNTAX) -js *.ml > $@

browser.cmjs: .cmjsdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -for-pack Browser -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -c -nostdlib -for-pack Browser -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -pack -o $@ `cat .cmjsdeps`

.PHONY: i-%
i-%:
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) -i $*.ml

.PHONY: clean
clean:
	rm -f *.cmjs *.cmo *.o *.cmi .mldeps .cmjsdeps *.annot *.a
	rm -rf ._d

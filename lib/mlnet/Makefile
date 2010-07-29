ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

# not using ocamldsort by default since it requires a bugfix
# to handle -pp properly, just storing output in repo directly
SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
NFLIB=$(ROOTDIR)/lib/netfront

.PHONY: build
build: depend mlnetlib.cmxa
	@ :

.PHONY: depend
depend: mpl_ethernet.ml

mpl_%.ml: %.mpl
	mplc -v $< > $@

.mldeps: *.ml *.mli
	$(OCAMLDSORT) $(SYNTAX) -mli *.ml *.mli > $@

.cmxdeps: .mldeps
	$(OCAMLDSORT) $(SYNTAX) -opt *.ml > $@

mlnetlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -annot -I $(STDLIB) -I $(LWTLIB) -I $(NFLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -a -o $@ `cat .cmxdeps`

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a mpl_*.ml
	rm -rf ._d

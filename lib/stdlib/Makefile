ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

.PHONY: build
build: stdlib.cmxa stdlib.cmjsa
	@ :

stdlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -nopervasives $(OCAMLOPT_FLAGS) \
	  pervasives.mli pervasives.ml `cat .mldeps`
	$(OCAMLOPT) -a -o $@ `cat .cmxdeps`

stdlib.cmjsa: .cmjsdeps .mldeps
	$(OCAMLJS) -c -nostdlib -nopervasives pervasives.mli pervasives.ml `cat .mldeps`
	$(OCAMLJS) -a -o $@ `cat .cmjsdeps`

include ../Makefile.common

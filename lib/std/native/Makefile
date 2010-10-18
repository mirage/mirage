ROOTDIR=../../..
include $(ROOTDIR)/mk/ocaml.mk

.PHONY: all
all: stdlib.cmxa
	@ :

stdlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -nopervasives $(OCAMLOPT_FLAGS) \
	  pervasives.mli pervasives.ml `cat .mldeps`
	$(OCAMLOPT) -a -o $@ `cat .cmxdeps`

include ../../Makefile.common

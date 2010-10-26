ROOTDIR=../../..
include $(ROOTDIR)/mk/ocaml.mk

stdlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -nopervasives $(OCAMLOPT_FLAGS) \
	  pervasives.mli pervasives.ml `cat .mldeps`
	$(OCAMLOPT) -a -o $@ `cat .cmxdeps`

TARGET=stdlib

include ../../Makefile.common

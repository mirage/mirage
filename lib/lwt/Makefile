ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

STDLIB=../stdlib

.PHONY: build
build: lwtlib.cmxa lwtlib.cmjsa
	@ :

lwtlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -annot -I $(STDLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -a -o $@ `cat .cmxdeps`

lwtlib.cmjsa: .cmjsdeps
	$(OCAMLJS) -c -nostdlib -I $(STDLIB) $(SYNTAX) `cat .mldeps`
	$(OCAMLJS) -a -o $@ `cat .cmjsdeps`

WITH_SYNTAX=yes
include ../Makefile.common

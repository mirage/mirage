ROOTDIR=../../../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=os/unix net/api 
	
%.cmx: %.mli %.ml
	$(OCAMLOPT) -c $(OCAMLOPT_ALLFLAGS) $^

TARGET=flow
WITH_SYNTAX=yes
include ../../../Makefile.common

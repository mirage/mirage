ROOTDIR=../../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=misc/xml misc/htcaml
SOURCES=atom.ml
TARGET=atom

%.cmx: %.mli %.ml
	$(OCAMLOPT) -c -annot $(OCAMLOPT_ALLFLAGS) $^

WITH_SYNTAX=yes
USE_PACK=no
include ../../Makefile.common

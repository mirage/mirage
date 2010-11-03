ROOTDIR=../../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=
SOURCES=xml.mli xml.ml
TARGET=xml

%.cmx: %.mli %.ml
	$(OCAMLOPT) -c $(OCAMLOPT_ALLFLAGS) $^

WITH_SYNTAX=yes
USE_PACK=no
include ../../Makefile.common

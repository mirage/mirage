ROOTDIR=../../..
include $(ROOTDIR)/mk/ocaml.mk

TARGET=nettypes
TARGET_MLI=nettypes.mli

.PHONY: all
all: nettypes.cmx
	@ :

nettypes.cmx: nettypes.mli nettypes.ml
	$(OCAMLOPT) -c -g -nostdlib -annot -o $@ $(INCLUDES) $(SYNTAX) $^

WITH_SYNTAX=yes
include ../../Makefile.common

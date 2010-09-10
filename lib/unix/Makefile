ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/lib/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
MPLLIB=$(ROOTDIR)/lib/mpl
INCLUDES=-I $(STDLIB) -I $(LWTLIB) -I $(MPLLIB)

.PHONY: build
build: unix.cmxa
	@ :

unix.ml: console.ml clock.ml activations.ml main.ml ethif.ml time.ml
	$(OCAMLPACK) -name unix $^ > $@

unix.cmx unix.cmi: unix.mli unix.ml
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $^

.PHONY: i-%
i-%:
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) -i $*.ml

WITH_SYNTAX=yes
EXTRA_CLEAN=unix.ml
include ../Makefile.common

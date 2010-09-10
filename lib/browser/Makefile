ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

INCLUDES=-I $(STDLIB) -I $(LWTLIB)

.PHONY: build
build: browser.cmjs
	@ :

browser.ml: activations.ml clock.ml console.ml main.ml time.ml
	$(OCAMLPACK) -name browser $^ > $@

browser.cmjs browser.cmi: browser.mli browser.ml
	$(OCAMLJS) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $^

.PHONY: i-%
i-%:
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) -i $*.ml

WITH_SYNTAX=yes
EXTRA_CLEAN=browser.ml
include ../Makefile.common


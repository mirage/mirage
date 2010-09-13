ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

INCLUDES=-I $(STDLIB) -I $(LWTLIB)

.PHONY: build
build: browser.cmxa browser.cmjsa
	@ :

SOURCES= activations.ml clock.ml console.ml time.ml websocket.ml main.ml
debug: $(SOURCES)
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(OCAMLOPT_FLAGS) $(SYNTAX) $^

browser.ml: $(SOURCES)
	$(OCAMLPACK) -name browser $^ > $@

browser.cmx: browser.mli browser.ml
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(OCAMLOPT_FLAGS) $(SYNTAX) $^

browser.cmjs browser.cmi: browser.mli browser.ml
	$(OCAMLJS) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $^

.PHONY: i-%
i-%:
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) -i $*.ml

WITH_SYNTAX=yes
EXTRA_CLEAN=browser.ml
include ../Makefile.common


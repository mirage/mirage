ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

INCLUDES=-I $(STDLIB) -I $(LWTLIB) -I $(MPLLIB)

.PHONY: build
build: xen.cmxa
	@ :

xen.ml: hw_page.mli hw_page.ml gnttab.mli gnttab.ml ring.ml evtchn.ml activations.ml \
	xb_op.ml xb_partial.ml xb_state.ml \
	xs_packet.ml xb.mli xb.ml queueop.ml xsraw.mli xsraw.ml \
	xst.mli xst.ml clock.ml main.ml time.ml xs.mli xs.ml ethif.ml console.mli console.ml 
	$(OCAMLPACK) -name xen $^ > $@

xen.cmx xen.cmi: xen.mli xen.ml
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $^

.PHONY: i-%
i-%:
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) -i $*.ml

WITH_SYNTAX=yes
EXTRA_CLEAN=xen.ml
include ../Makefile.common

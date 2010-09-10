ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk
STDLIB=$(ROOTDIR)/lib/stdlib

.PHONY: build
build: mpl.cmxa mpl.cmjsa
	@ :

MPL=ethernet ipv4 udp icmp dhcp dns_rr dns tcp

.PHONY: depend
depend: $(MPLDEPS)
	@ :

%.ml: %.mpl
	mplc -v $< > $@

mpl.ml: mpl_stdlib.mli mpl_stdlib.ml $(MPL:%=%.ml)
	rm -f $@
	$(OCAMLPACK) -name mpl $^ > $@

mpl.cmx: mpl.ml
	$(OCAMLOPT) -c -w y -nostdlib -annot -I $(STDLIB) $(OCAMLOPT_FLAGS) $<

mpl.cmjs: mpl.ml
	$(OCAMLJS) -c -w y -nostdlib -annot -I $(STDLIB) $<

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -I $(STDLIB) $(OCAMLOPT_FLAGS) $*.ml

WITH_SYNTAX=yes
EXTRA_CLEAN=mpl.ml
include ../Makefile.common

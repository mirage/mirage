ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk
STDLIB=$(ROOTDIR)/lib/stdlib

.PHONY: build
build: mpl.cmxa
	@ :

MPL=ethernet ipv4 udp icmp dhcp dns_rr dns tcp
MPLDEPS=$(MPL:%=%.ml)
MPLCMX=$(MPL:%=%.cmx)
MPLCMJS=$(MPL:%=%.cmjs)

.PHONY: depend
depend: $(MPLDEPS)
	@ :

%.ml: %.mpl
	mplc -v $< > $@

mpl.cmx: $(MPLDEPS) mpl_stdlib.mli mpl_stdlib.ml
	$(OCAMLOPT) -c -nostdlib -annot -for-pack Mpl -I $(STDLIB) $(OCAMLOPT_FLAGS) mpl_stdlib.mli mpl_stdlib.ml
	$(OCAMLOPT) -c -w y -nostdlib -annot -for-pack Mpl -I $(STDLIB) $(OCAMLOPT_FLAGS) $(MPLDEPS)
	$(OCAMLOPT) -pack -o $@ mpl_stdlib.cmx $(MPLCMX)

mpl.cmjs: $(MPLDEPS) mpl_stdlib.mli mpl_stdlib.ml
	$(OCAMLJS) -c -nostdlib -annot -for-pack Mpl -I $(STDLIB) mpl_stdlib.mli mpl_stdlib.ml
	$(OCAMLJS) -c -w y -nostdlib -annot -for-pack Mpl -I $(STDLIB) $(MPLDEPS)
	$(OCAMLJS) -pack -o $@ mpl_stdlib.cmjs $(MPLCMJS)
	

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -I $(STDLIB) $(OCAMLOPT_FLAGS) $*.ml

WITH_SYNTAX=yes
include ../Makefile.common


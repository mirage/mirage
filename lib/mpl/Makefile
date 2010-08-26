ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

STDLIB=$(ROOTDIR)/lib/stdlib

.PHONY: build
build: mpl.cmx
	@ :

MPL=ethernet ipv4 udp icmp dhcp
MPLDEPS=$(MPL:%=%.ml)
MPLCMX=$(MPL:%=%.cmx)

.PHONY: depend
depend: $(MPLDEPS)

%.ml: %.mpl
	mplc -v $< > $@

mpl.cmx: $(MPLDEPS) mpl_stdlib.mli mpl_stdlib.ml
	$(OCAMLOPT) -c -nostdlib -annot -for-pack Mpl -I $(STDLIB) $(OCAMLOPT_FLAGS) mpl_stdlib.mli mpl_stdlib.ml
	$(OCAMLOPT) -c -w y -nostdlib -annot -for-pack Mpl -I $(STDLIB) $(OCAMLOPT_FLAGS) $(MPLDEPS)
	$(OCAMLOPT) -pack -o $@ mpl_stdlib.cmx $(MPLCMX)

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -I $(STDLIB) $(OCAMLOPT_FLAGS) $*.ml

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a
	rm -rf ._d

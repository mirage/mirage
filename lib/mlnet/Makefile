ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/lib/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
XENLIB=$(ROOTDIR)/lib/xen
MPLLIB=$(ROOTDIR)/lib/mpl

.PHONY: build
build: mlnet.cmx
	@ :

mlnet.cmx: *.ml *.mli
	$(OCAMLOPT) -c -nostdlib -annot -for-pack Mlnet -I $(STDLIB) -I $(LWTLIB) -I $(XENLIB) -I $(MPLLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) mlnet_types.mli mlnet_types.ml checksum.ml arp.ml frame.mli ethif.mli dhcp.ml frame.ml ethif.ml
	$(OCAMLOPT) -pack -o $@ mlnet_types.cmx checksum.cmx arp.cmx dhcp.cmx frame.cmx ethif.cmx

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -I $(STDLIB) -I $(LWTLIB) -I $(XENLIB) -I $(MPLLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) $*.ml

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a mpl_*.ml
	rm -rf ._d

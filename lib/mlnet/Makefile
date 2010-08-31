ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/lib/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
MPLLIB=$(ROOTDIR)/lib/mpl
INCLUDES=-I $(ROOTDIR)/lib/stdlib -I $(ROOTDIR)/lib/lwt -I $(ROOTDIR)/lib/mpl

SOURCES=mlnet_types.mli mlnet_types.ml checksum.ml ethif.ml arp.ml ipv4.ml icmp.ml udp.ml dhcp_option.ml dhcp.ml
CMX=mlnet_types.cmx checksum.cmx ethif.cmx arp.cmx ipv4.cmx icmp.cmx udp.cmx dhcp_option.cmx dhcp.cmx

.PHONY: build
build: mlnet.cmx
	@ :

$(CMX): $(SOURCES)
	$(OCAMLOPT) -c -nostdlib -annot -for-pack Mlnet $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $(SOURCES)

mlnet.cmx: $(CMX)
	$(OCAMLOPT) -pack -o $@ $^

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -annot -for-pack Mlnet $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $*.ml

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a mpl_*.ml
	rm -rf ._d

ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

INCLUDES=-I $(STDLIB) -I $(LWTLIB) -I $(MPLLIB)

SOURCES=mlnet_types.mli mlnet_types.ml checksum.ml ethif.ml arp.ml ipv4.ml \
	udp.ml icmp.ml dhcp_option.ml dhcp.ml tcp.ml

.PHONY: build
build: mlnet.cmxa mlnet.cmjsa
	@ :

mlnet.ml: $(SOURCES)
	$(OCAMLPACK) -name mlnet $^ > $@

mlnet.cmx: mlnet.ml
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $<

mlnet.cmjs: mlnet.ml
	$(OCAMLJS) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $<

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -annot -for-pack Mlnet $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $*.ml

EXTRA_CLEAN=mlnet.ml
WITH_SYNTAX=yes
include ../Makefile.common

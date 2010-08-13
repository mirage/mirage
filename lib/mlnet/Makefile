ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'

STDLIB=$(ROOTDIR)/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
NFLIB=$(ROOTDIR)/lib/netfront

.PHONY: build
build: depend mlnet.cmxa
	@ :

MPL=ethernet ipv4 udp icmp
MPLDEPS=$(MPL:%=mpl_%.ml)
MLDEPS=$(MPLDEPS) mlnet_types.mli mpl_ethernet.ml netif.mli frame.mli arp.mli mlnet_types.ml frame.ml arp.ml netif.ml
.PHONY: depend
depend: $(MPLDEPS)

mpl_%.ml: %.mpl
	mplc -v $< > $@


.mldeps: *.ml *.mli
	$(OCAMLDSORT) $(SYNTAX) -mli *.ml *.mli > $@

.cmxdeps: .mldeps
	$(OCAMLDSORT) $(SYNTAX) -opt *.ml > $@

mlnet.cmx: .cmxdeps .mldeps
	# run it twice to get the cross-module optimisation for cmx and let -for-pack work (XXX investigate further!)
	$(OCAMLOPT) -c -nostdlib -annot -for-pack Mlnet -I $(STDLIB) -I $(LWTLIB) -I $(NFLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -c -nostdlib -annot -for-pack Mlnet -I $(STDLIB) -I $(LWTLIB) -I $(NFLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) `cat .mldeps`
	$(OCAMLOPT) -pack -o $@ `cat .cmxdeps`

%.cmxa: %.cmx
	$(OCAMLOPT) -a -o $@ $<

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -I $(STDLIB) -I $(LWTLIB) -I $(NFLIB) $(SYNTAX) $(OCAMLOPT_FLAGS) $*.ml

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a mpl_*.ml
	rm -rf ._d

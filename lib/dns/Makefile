ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SYNTAX=-pp 'camlp4o -I $(ROOTDIR)/syntax pa_mirage.cma'
SYNTAX=

STDLIB=$(ROOTDIR)/lib/stdlib
LWTLIB=$(ROOTDIR)/lib/lwt
MPLLIB=$(ROOTDIR)/lib/mpl
INCLUDES=-I $(ROOTDIR)/lib/stdlib -I $(ROOTDIR)/lib/lwt -I $(ROOTDIR)/lib/mpl

SOURCES=dnsparameters.ml hashcons.mli dnsserver.mli dnsparser.mli hashcons.ml dnsrr.mli \
	dnsrr.ml dnstrie.mli dnstrie.ml dnsquery.mli dnsloader.mli dnsquery.ml \
	dnsparser.ml dnsloader.ml dnslexer.ml dnsserver.ml
CMX=hashcons.cmx dnsparameters.cmx dnsrr.cmx dnstrie.cmx dnsquery.cmx dnsloader.cmx \
  dnsparser.cmx dnslexer.cmx dnsserver.cmx

.PHONY: build
build: dns.cmx
	@ :

dnslexer.ml: dnslexer.mll
	ocamllex $<

dnsparser.mli dnsparser.ml: dnsparser.mly
	ocamlyacc $<

$(CMX): $(SOURCES)
	$(OCAMLOPT) -c -nostdlib -annot -for-pack Dns $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $(SOURCES)
	$(OCAMLOPT) -c -nostdlib -annot -for-pack Dns $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $(SOURCES)

dns.cmx: $(CMX)
	$(OCAMLOPT) -pack -o $@ $^

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -annot -for-pack Dns $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $*.ml

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.annot *.a dnslexer.ml dnsparser.mli dnsparser.ml
	rm -rf ._d

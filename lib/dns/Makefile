ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

INCLUDES=-I $(STDLIB) -I $(LWTLIB) -I $(MPLLIB)

SOURCES=dnsparameters.ml hashcons.mli hashcons.ml dnsrr.mli dnsrr.ml dnstrie.mli dnstrie.ml dnsquery.mli dnsquery.ml \
	dnsloader.mli dnsloader.ml dnsparser.mli dnsparser.ml dnslexer.ml dnsserver.mli dnsserver.ml

.PHONY: build
build: dns.cmxa dns.cmjsa
	@ :

dnslexer.ml: dnslexer.mll
	ocamllex $<

dnsparser.mli dnsparser.ml: dnsparser.mly
	ocamlyacc $<

dns.ml: $(SOURCES)
	$(OCAMLPACK) -name dns -no-source-lines dnsparser.ml \
	  -no-source-lines dnsparser.mli -no-source-lines dnslexer.ml $^ > $@

dns.cmx: dns.ml
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $<

dns.cmjs: dns.ml
	$(OCAMLJS) -c -nostdlib $(INCLUDES) $(SYNTAX) $<

.PHONY: i-%
i-%:
	$(OCAMLOPT) -i -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $*.ml

EXTRA_CLEAN=dns.ml dnslexer.ml dnsparser.mli dnsparser.ml
WITH_SYNTAX=yes
include ../Makefile.common

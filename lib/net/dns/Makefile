ROOTDIR=../../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=lwt mpl 
SOURCES=dnsparameters.ml hashcons.mli hashcons.ml dnsrr.mli dnsrr.ml dnstrie.mli dnstrie.ml dnsquery.mli dnsquery.ml \
	dnsloader.mli dnsloader.ml dnsparser.mli dnsparser.ml dnslexer.ml dnsserver.mli dnsserver.ml

.PHONY: build
build: mldns.cmxa mldns.cmjsa
	@ :

dnslexer.ml: dnslexer.mll
	ocamllex $<

dnsparser.mli dnsparser.ml: dnsparser.mly
	ocamlyacc $<

mldns.ml: $(SOURCES)
	$(OCAMLPACK) -name $(@F) -no-source-lines dnsparser.ml \
	  -no-source-lines dnsparser.mli -no-source-lines dnslexer.ml $^ > $@

mldns.cmx: mldns.ml
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $<

mldns.cmjs: mldns.ml
	$(OCAMLJS) -c -nostdlib $(INCLUDES) $(SYNTAX) $<

EXTRA_CLEAN=mldns.ml dnslexer.ml dnsparser.mli dnsparser.ml
WITH_SYNTAX=yes
include ../../Makefile.common

ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=lwt mpl 
#SOURCES=dnsparameters.ml hashcons.mli hashcons.ml dnsrr.mli dnsrr.ml dnstrie.mli dnstrie.ml dnsquery.mli dnsquery.ml \
#	dnsloader.mli dnsloader.ml dnsparser.mli dnsparser.ml dnslexer.ml dnsserver.mli dnsserver.ml

SOURCES=resolv.ml

.PHONY: build
build: mlresolv.cmxa mlresolv.cmjsa
	@ :

#dnslexer.ml: dnslexer.mll
#	ocamllex $<
#
#dnsparser.mli dnsparser.ml: dnsparser.mly
#	ocamlyacc $<

mlresolv.ml: $(SOURCES)
	$(OCAMLPACK) -name $(@F) -no-source-lines dnsparser.ml \
	  -no-source-lines dnsparser.mli -no-source-lines dnslexer.ml $^ > $@

mlresolv.cmx: mlresolv.ml
	$(OCAMLOPT) -c -nostdlib -annot $(INCLUDES) $(SYNTAX) $(OCAMLOPT_FLAGS) $<

mlresolv.cmjs: mlresolv.ml
	$(OCAMLJS) -c -nostdlib $(INCLUDES) $(SYNTAX) $<

EXTRA_CLEAN=mlresolv.ml # dnslexer.ml dnsparser.mli dnsparser.ml
WITH_SYNTAX=yes
include ../Makefile.common

ROOTDIR=..
include $(ROOTDIR)/mk/base.mk
include $(ROOTDIR)/mk/ocaml.mk

SOURCES=stdlib lwt mpl xen unix mlnet
LIBDIR=../lib
HTMLDIR=html
SYNTAX=-pp 'camlp4o -I ../syntax pa_mirage.cma'

.PHONY: all

all: $(SOURCES:%=$(HTMLDIR)/%/index.html)
	@ :

stdlib.odoc:
	$(OCAMLDOC) -dump $@ -nopervasives -nostdlib -I $(LIBDIR)/stdlib $(LIBDIR)/stdlib/*.ml $(LIBDIR)/stdlib/*.mli

lwt.odoc:
	$(OCAMLDOC) -dump $@ -nostdlib $(SYNTAX) -I $(LIBDIR)/stdlib -I $(LIBDIR)/lwt $(LIBDIR)/lwt/*.ml $(LIBDIR)/lwt/*.mli

mpl.odoc:
	$(OCAMLDOC) -dump $@ -nostdlib -pack Mpl -I $(LIBDIR)/stdlib -I $(LIBDIR)/mpl $(LIBDIR)/mpl/*.ml $(LIBDIR)/mpl/*.mli

xen.odoc:
	$(OCAMLDOC) -dump $@ -nostdlib $(SYNTAX) -I $(LIBDIR)/stdlib -I $(LIBDIR)/lwt -I $(LIBDIR)/obj -I $(LIBDIR)/xen $(LIBDIR)/xen/*.ml $(LIBDIR)/xen/*.mli

unix.odoc:
	$(OCAMLDOC) -dump $@ -nostdlib $(SYNTAX) -I $(LIBDIR)/stdlib -I $(LIBDIR)/lwt -I $(LIBDIR)/obj -I $(LIBDIR)/unix $(LIBDIR)/unix/*.ml $(LIBDIR)/unix/*.mli

mlnet.odoc:
	$(OCAMLDOC) -dump $@ -nostdlib $(SYNTAX) -I $(LIBDIR)/stdlib -I $(LIBDIR)/lwt -I $(LIBDIR)/obj -I $(LIBDIR)/mlnet $(LIBDIR)/mlnet/*.ml $(LIBDIR)/mlnet/*.mli
	
HTMLSTAMP=$(HTMLDIR)/.stamp
$(HTMLSTAMP):
	@rm -rf $(HTMLDIR)
	@mkdir -p $(HTMLDIR)
	@touch $@

$(HTMLDIR)/%/index.html: %.odoc $(HTMLSTAMP)
	rm -rf $(HTMLDIR)/$*
	mkdir -p $(HTMLDIR)/$*
	$(OCAMLDOC) -load $< -html -d $(@D)

.PHONY: clean
clean:
	rm -f *.odoc 
	rm -rf $(HTMLDIR)

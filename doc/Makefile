ROOTDIR=..
include $(ROOTDIR)/mk/base.mk
include $(ROOTDIR)/mk/ocaml.mk

OTHERLIBS=mpl xen browser unix mlnet
SOURCES=stdlib lwt $(OTHERLIBS)
LIBDIR=../lib
HTMLDIR=html
SYNTAX=-pp 'camlp4o -I ../syntax pa_mirage.cma'

.PHONY: all

all: $(HTMLDIR)/index.html
	@ :

stdlib.odoc:
	$(OCAMLDOC) -dump $@ -nopervasives -nostdlib -I $(LIBDIR)/stdlib $(LIBDIR)/stdlib/*.ml $(LIBDIR)/stdlib/*.mli

other.odoc:
	$(OCAMLDOC) -dump $@ -nostdlib $(SYNTAX) $(SOURCES:%=-I $(LIBDIR)/%) $(LIBDIR)/lwt/*.mli $(LIBDIR)/lwt/*.ml $(LIBDIR)/mpl/mpl.ml $(LIBDIR)/xen/xen.ml $(LIBDIR)/browser/browser.ml $(LIBDIR)/unix/unix.ml $(LIBDIR)/mlnet/mlnet.ml 

$(HTMLDIR)/index.html: stdlib.odoc other.odoc
	@rm -rf $(HTMLDIR)
	@mkdir -p $(HTMLDIR)
	$(OCAMLDOC) $(^:%=-load %) -html -d $(@D)

.PHONY: clean
clean:
	rm -f *.odoc 
	rm -rf $(HTMLDIR)

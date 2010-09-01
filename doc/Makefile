
OCAMLDOC=ocamldoc
SOURCES=stdlib lwt mpl xen unix mlnet
LIBDIR=../lib
HTMLDIR=html
SYNTAX=-pp 'camlp4o -I ../syntax pa_mirage.cma'

.PHONY: all

all: $(SOURCES:%=$(HTMLDIR)/%/index.html)
	@ :

stdlib.odoc:
	ocamldoc -dump $@ -nopervasives -nostdlib -I $(LIBDIR)/stdlib $(LIBDIR)/stdlib/*.ml $(LIBDIR)/stdlib/*.mli

lwt.odoc:
	ocamldoc -dump $@ -nostdlib $(SYNTAX) -I $(LIBDIR)/stdlib -I $(LIBDIR)/lwt $(LIBDIR)/lwt/*.ml $(LIBDIR)/lwt/*.mli

mpl.odoc:
	ocamldoc -dump $@ -nostdlib -I $(LIBDIR)/stdlib -I $(LIBDIR)/mpl $(LIBDIR)/mpl/*.ml $(LIBDIR)/mpl/*.mli

xen.odoc:
	ocamldoc -dump $@ -nostdlib $(SYNTAX) -I $(LIBDIR)/stdlib -I $(LIBDIR)/lwt -I $(LIBDIR)/obj -I $(LIBDIR)/xen $(LIBDIR)/xen/*.ml $(LIBDIR)/xen/*.mli

unix.odoc:
	ocamldoc -dump $@ -nostdlib $(SYNTAX) -I $(LIBDIR)/stdlib -I $(LIBDIR)/lwt -I $(LIBDIR)/obj -I $(LIBDIR)/unix $(LIBDIR)/unix/*.ml $(LIBDIR)/unix/*.mli

mlnet.odoc:
	ocamldoc -dump $@ -nostdlib $(SYNTAX) -I $(LIBDIR)/stdlib -I $(LIBDIR)/lwt -I $(LIBDIR)/obj -I $(LIBDIR)/mlnet $(LIBDIR)/mlnet/*.ml $(LIBDIR)/mlnet/*.mli
	
HTMLSTAMP=$(HTMLDIR)/.stamp
$(HTMLSTAMP):
	@rm -rf $(HTMLDIR)
	@mkdir -p $(HTMLDIR)
	@touch $@

$(HTMLDIR)/%/index.html: %.odoc $(HTMLSTAMP)
	rm -rf $(HTMLDIR)/$*
	mkdir -p $(HTMLDIR)/$*
	ocamldoc -load $< -html -d $(@D)

.PHONY: clean
clean:
	rm -f *.odoc 
	rm -rf $(HTMLDIR)

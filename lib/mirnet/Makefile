ROOTDIR = ../..

MODE ?= xen

include $(ROOTDIR)/mk/ocaml.mk
include $(ROOTDIR)/mk/$(MODE).mk

OBJDIR=obj-$(MODE)

.PHONY: all
all: $(OBJDIR)/libmirnet.a $(OBJDIR)/mirnet.cmx
	@ :

$(OBJDIR)/%.o: %.c $(OBJDIR)/.stamp
	$(CC) -c $(CFLAGS) -o $@ $<

TARGS=$(wildcard *.c)

$(OBJDIR)/.stamp:
	mkdir -p $(OBJDIR)
	touch $@

$(OBJDIR)/libmirnet.a: $(TARGS:%.c=$(OBJDIR)/%.o)
	ar rc $@ $^
	ranlib $@

# ocaml leaves tmp files in curdir, so copy file
$(OBJDIR)/%.cmx: %.ml
	cp $< $(OBJDIR)/$<
	$(OCAMLOPT_BUILD) -c $(OBJDIR)/$< $@

.PHONY: clean
clean:
	rm -f *.o *.a *.cmx *.cmi
	rm -rf $(OBJDIR)

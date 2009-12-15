ROOTDIR = ../../..

MODE ?= xen

include $(ROOTDIR)/mk/ocaml.mk
include $(ROOTDIR)/mk/$(MODE).mk

OBJDIR ?= obj-$(MODE)
TARGS=$(wildcard *.c)
CFLAGS += -I"$(shell $(OCAMLC) -where)/caml"

.PHONY: all
all: $(OBJDIR)/libmir.a
	@ :

$(OBJDIR)/%.o: %.c $(OBJDIR)/.stamp
	$(CC) -c $(CFLAGS) -o $@ $<

$(OBJDIR)/.stamp:
	mkdir -p $(OBJDIR)
	touch $@

$(OBJDIR)/libmir.a: $(TARGS:%.c=$(OBJDIR)/%.o)
	ar rc $@ $^
	ranlib $@

.PHONY: clean
clean:
	rm -f *.o *.a *.cmx *.cmi
	rm -rf $(OBJDIR)

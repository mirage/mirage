ROOTDIR = ../..

include $(ROOTDIR)/mk/xen.mk

TARGS=$(wildcard *.c)

.PHONY: all
all: libmirnet.a
	@ :

libmirnet.a: $(TARGS:%.c=%.o)
	ar rc $@ $^
	ranlib $@

.PHONY: clean
clean:
	rm -f *.o *.a

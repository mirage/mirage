ROOTDIR=..
include $(ROOTDIR)/mk/xen.mk

TARGS = libmiragerun_xen.a libc.a libmir.a

CROSS_PREFIX = inst-x86_64

.PHONY: all clean install
all: $(TARGS:%=$(CROSS_PREFIX)/lib/%)
	@ :

$(CROSS_PREFIX)/lib/libc.a:
	cd dietlibc && $(MAKE) all install

$(CROSS_PREFIX)/lib/libmiragerun_xen.a:
	cd base && $(MAKE) MODE=xen
	mkdir -p $(CROSS_PREFIX)/lib
	cp base/obj-xen/libmiragerun_xen.a $@

$(CROSS_PREFIX)/lib/libmir.a:
	cd bindings && $(MAKE) MODE=xen
	mkdir -p $(CROSS_PREFIX)/lib
	cp bindings/obj-xen/libmir.a $@

clean:
	rm -rf base/obj-*
	rm -rf bindings/obj-*
	cd dietlibc && $(MAKE) clean
	rm -rf $(CROSS_PREFIX)

ROOTDIR=../..
include $(ROOTDIR)/mk/xen.mk

TARGS = libmiragerun_xen.a libc.a libm.a 

CROSS_PREFIX = inst-x86_64

.PHONY: all clean install
all: $(TARGS:%=$(CROSS_PREFIX)/lib/%)
	@ :

STAMP=$(CROSS_PREFIX)/lib/.stamp
$(STAMP):
	mkdir -p $(CROSS_PREFIX)/lib
	@touch $@

$(CROSS_PREFIX)/lib/libc.a: $(STAMP)
	cd dietlibc && $(MAKE) all install

$(CROSS_PREFIX)/lib/libmiragerun_xen.a: $(STAMP)
	cd base && $(MAKE) MODE=xen
	cp base/obj-xen/libmiragerun_xen.a $@

$(CROSS_PREFIX)/lib/libm.a: $(STAMP)
	cd libm && $(MAKE)
	cp libm/obj/libm.a $@

clean:
	rm -rf base/obj-*
	rm -rf bindings/obj-*
	rm -rf kernel/obj
	rm -rf libm/obj-*
	cd dietlibc && $(MAKE) clean
	rm -rf $(CROSS_PREFIX)

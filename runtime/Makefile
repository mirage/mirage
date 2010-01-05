ROOTDIR=..
include $(ROOTDIR)/mk/base.mk

TARGS = libmiragerun_$(OS).a
ifeq ($(OS), linux)
TARGS += libmiragerun_xen.a
endif

.PHONY: all clean install
all: $(TARGS)
	@ :

CROSS_XEN=$(CURDIR)/xen/stubdom/cross-root-x86_64/x86_64-xen-elf/
$(CROSS_XEN)/lib/libc.a:
	cd xen/stubdom && $(MAKE) cross debug=$(debug)

libmiragerun_xen.a: $(CROSS_XEN)/lib/libc.a
	@cd base && $(MAKE) MODE=xen

libmiragerun_%.a:
	@cd base && $(MAKE) MODE=$*

clean:
	rm -rf base/obj-*
	rm -rf base/mir/obj-*
	rm -f libmiragerun*
	cd xen/stubdom && $(MAKE) clean crossclean

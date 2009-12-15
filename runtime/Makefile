OS = $(shell uname -s)
OCAML_PREFIX = $(shell ocamlopt -where)

TARGS = 
ifeq ($(OS), Linux)
TARGS += libmiragerun_linux.a
TARGS += libmiragerun_xen.a
endif
ifeq ($(OS), Darwin)
TARGS += libmiragerun_darwin.a
endif

.PHONY: all clean install

all: $(TARGS)
	@ :

xen: libmiragerun_xen.a
	@ :

clean:
	rm -rf base/obj-*
	rm -f libmiragerun*
	cd xen/stubdom && $(MAKE) clean crossclean

libmiragerun_darwin.a:
	@cd base && $(MAKE) MODE=darwin CC="$(CC)"
libmiragerun_linux.a:
	@cd base && $(MAKE) MODE=linux CC="$(CC)"

CROSS_XEN=$(CURDIR)/xen/stubdom/cross-root-x86_64/x86_64-xen-elf/
$(CROSS_XEN)/lib/libc.a:
	cd xen/stubdom && $(MAKE) cross

libmiragerun_xen.a: $(CROSS_XEN)/lib/libc.a
	@cd base && $(MAKE) MODE=xen

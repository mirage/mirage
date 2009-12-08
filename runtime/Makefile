.PHONY: all clean install

OCAML_PREFIX=$(shell ocamlopt -where)

all: libmiragerun_linux.a libmiragerun_xen.a
	@ :

xen: libmiragerun_xen.a
	@ :

clean:
	rm -rf base/obj-*
	rm -f libmiragerun*

libmiragerun_linux.a:
	@cd base && $(MAKE) MODE=linux CC="$(CC)"

# xen build needs to be compiled against the newlib headers
# and not the system ones
GCC_INSTALL = $(shell LANG=C $(CC) -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p')
CROSS_XEN=$(CURDIR)/xen/stubdom/cross-root-x86_64/x86_64-xen-elf/
libmiragerun_xen.a:
	@cd base && $(MAKE) MODE=xen CC="$(CC) -nostdinc \
	  -U __linux__ -U __FreeBSD__ -U __sun_ -D__MINIOS__ \
	  -isystem $(CURDIR)/xen/extras/mini-os/include/posix \
	  -isystem $(CURDIR)/xen/extras/mini-os/include/x86 \
	  -isystem $(CROSS_XEN)/include \
	  -isystem $(GCC_INSTALL)/include \
	  " all


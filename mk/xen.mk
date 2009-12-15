# before including this, define ROOTDIR to the repository root

CC = gcc

CROSS_PREFIX = $(ROOTDIR)/runtime/xen/stubdom/cross-root-x86_64/x86_64-xen-elf/include
GCC_INSTALL = $(shell LANG=C $(CC) -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p')
CFLAGS = -U __linux__ -U __FreeBSD__ -U __sun__
CFLAGS += -O2
CFLAGS += -D__MiniOS__ -DHAVE_LIBC -D__x86_64__
CFLAGS += -nostdinc
CFLAGS += -isystem $(ROOTDIR)/runtime/xen/extras/mini-os/include/posix
CFLAGS += -isystem $(ROOTDIR)/runtime/xen/extras/mini-os/include
CFLAGS += -isystem $(CROSS_PREFIX) 
CFLAGS += -isystem $(GCC_INSTALL)/include
CFLAGS += -isystem $(ROOTDIR)/runtime/xen/stubdom/lwip/src/include
CFLAGS += -isystem $(ROOTDIR)/runtime/xen/stubdom/lwip/src/include/ipv4
CFLAGS += -isystem $(ROOTDIR)/runtime/xen/extras/mini-os/include/x86
CFLAGS += -isystem $(ROOTDIR)/runtime/xen/extras/mini-os/include/x86/x86_64
CFLAGS += -isystem $(ROOTDIR)/runtime/xen/xen/include
CFLAGS += -fno-stack-protector

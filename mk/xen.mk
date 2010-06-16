# before including this, define ROOTDIR to the repository root
include $(ROOTDIR)/mk/base.mk

GCC_INSTALL = $(shell LANG=C $(CC) -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p')
CFLAGS = -U __linux__ -U __FreeBSD__ -U __sun__
CFLAGS += $(DEBUG_CFLAGS)
CFLAGS += -D__MiniOS__ -DHAVE_LIBC -D__x86_64__
CFLAGS += -nostdinc -std=gnu99
CFLAGS += -fno-stack-protector
CFLAGS += -isystem $(GCC_INSTALL)/include
CFLAGS += -isystem $(ROOTDIR)/runtime/include
CFLAGS += -isystem $(ROOTDIR)/runtime/include/mini-os
CFLAGS += -isystem $(ROOTDIR)/runtime/include/mini-os/x86

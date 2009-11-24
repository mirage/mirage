#  -*- mode: Makefile; -*-

# `all' is the default target
all:

include $(XEN_ROOT)/Config.mk

export _INSTALL := $(INSTALL)
INSTALL = $(XEN_ROOT)/tools/cross-install

XEN_INCLUDE        = $(XEN_ROOT)/tools/include
XEN_XC             = $(XEN_ROOT)/tools/python/xen/lowlevel/xc
XEN_LIBXC          = $(XEN_ROOT)/tools/libxc
XEN_XENSTORE       = $(XEN_ROOT)/tools/xenstore
XEN_LIBXENSTAT     = $(XEN_ROOT)/tools/xenstat/libxenstat/src

CFLAGS_include = -I$(XEN_INCLUDE)

CFLAGS_libxenctrl = -I$(XEN_LIBXC) $(CFLAGS_include)
LDFLAGS_libxenctrl = -L$(XEN_LIBXC) -lxenctrl

CFLAGS_libxenguest = -I$(XEN_LIBXC) $(CFLAGS_include)
LDFLAGS_libxenguest = -L$(XEN_LIBXC) -lxenguest

CFLAGS_libxenstore = -I$(XEN_XENSTORE) $(CFLAGS_include)
LDFLAGS_libxenstore = -L$(XEN_XENSTORE) -lxenstore

X11_LDPATH = -L/usr/X11R6/$(LIBLEAFDIR)

CFLAGS += -D__XEN_TOOLS__

# Get gcc to generate the dependencies for us.
CFLAGS += -MMD -MF .$(@F).d
DEPS = .*.d

ifneq ($(XEN_OS),NetBSD)
# Enable implicit LFS support *and* explicit LFS names.
CFLAGS  += $(shell getconf LFS_CFLAGS)
CFLAGS  += -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
LDFLAGS += $(shell getconf LFS_LDFLAGS)
endif

# 32-bit x86 does not perform well with -ve segment accesses on Xen.
CFLAGS-$(CONFIG_X86_32) += $(call cc-option,$(CC),-mno-tls-direct-seg-refs)
CFLAGS += $(CFLAGS-y)

# Require GCC v3.4+ (to avoid issues with alignment constraints in Xen headers)
check-$(CONFIG_X86) = $(call cc-ver-check,CC,0x030400,\
                        "Xen requires at least gcc-3.4")
$(eval $(check-y))

DEFAULT_PYTHON_PATH := $(shell $(XEN_ROOT)/tools/python/get-path)
PYTHON_PATH ?= $(DEFAULT_PYTHON_PATH)
INSTALL_PYTHON_PROG = \
	$(XEN_ROOT)/tools/python/install-wrap "$(PYTHON_PATH)" $(INSTALL_PROG)

%.opic: %.c
	$(CC) $(CPPFLAGS) -DPIC $(CFLAGS) -fPIC -c -o $@ $<

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

%.o: %.cc
	$(CC) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

subdirs-all subdirs-clean subdirs-install: .phony
	@set -e; for subdir in $(SUBDIRS) $(SUBDIRS-y); do \
		$(MAKE) subdir-$(patsubst subdirs-%,%,$@)-$$subdir; \
	done

subdir-all-% subdir-clean-% subdir-install-%: .phony
	$(MAKE) -C $* $(patsubst subdir-%-$*,%,$@)

# -*- mode: Makefile; -*-

# A debug build of Xen and tools?
debug ?= y

XEN_COMPILE_ARCH    ?= $(shell uname -m | sed -e s/i.86/x86_32/ \
                         -e s/i86pc/x86_32/ -e s/amd64/x86_64/)
XEN_TARGET_ARCH     ?= $(XEN_COMPILE_ARCH)
XEN_OS              ?= $(shell uname -s)

CONFIG_$(XEN_OS) := y

SHELL     ?= /bin/sh

# Tools to run on system hosting the build
HOSTCC      = gcc
HOSTCFLAGS  = -Wall -Werror -Wstrict-prototypes -O2 -fomit-frame-pointer
HOSTCFLAGS += -fno-strict-aliasing

DISTDIR     ?= $(XEN_ROOT)/dist
DESTDIR     ?= /

# Allow phony attribute to be listed as dependency rather than fake target
.PHONY: .phony

include $(XEN_ROOT)/config/$(XEN_OS).mk
include $(XEN_ROOT)/config/$(XEN_TARGET_ARCH).mk

SHAREDIR    ?= $(PREFIX)/share
DOCDIR      ?= $(SHAREDIR)/doc/xen
MANDIR      ?= $(SHAREDIR)/man

ifneq ($(EXTRA_PREFIX),)
EXTRA_INCLUDES += $(EXTRA_PREFIX)/include
EXTRA_LIB += $(EXTRA_PREFIX)/$(LIBLEAFDIR)
endif

PYTHON      ?= python
PYTHON_PREFIX_ARG ?= --prefix="$(PREFIX)"
# The above requires that PREFIX contains *no spaces*. This variable is here
# to permit the user to set PYTHON_PREFIX_ARG to '' to workaround this bug:
#  https://bugs.launchpad.net/ubuntu/+bug/362570

# cc-option: Check if compiler supports first option, else fall back to second.
# Usage: cflags-y += $(call cc-option,$(CC),-march=winchip-c6,-march=i586)
cc-option = $(shell if test -z "`$(1) $(2) -S -o /dev/null -xc \
              /dev/null 2>&1`"; then echo "$(2)"; else echo "$(3)"; fi ;)

# cc-option-add: Add an option to compilation flags, but only if supported.
# Usage: $(call cc-option-add CFLAGS,CC,-march=winchip-c6)
cc-option-add = $(eval $(call cc-option-add-closure,$(1),$(2),$(3)))
define cc-option-add-closure
    ifneq ($$(call cc-option,$$($(2)),$(3),n),n)
        $(1) += $(3)
    endif
endef

# cc-ver: Check compiler is at least specified version. Return boolean 'y'/'n'.
# Usage: ifeq ($(call cc-ver,$(CC),0x030400),y)
cc-ver = $(shell if [ $$((`$(1) -dumpversion | awk -F. \
           '{ printf "0x%02x%02x%02x", $$1, $$2, $$3}'`)) -ge $$(($(2))) ]; \
           then echo y; else echo n; fi ;)

# cc-ver-check: Check compiler is at least specified version, else fail.
# Usage: $(call cc-ver-check,CC,0x030400,"Require at least gcc-3.4")
cc-ver-check = $(eval $(call cc-ver-check-closure,$(1),$(2),$(3)))
define cc-ver-check-closure
    ifeq ($$(call cc-ver,$$($(1)),$(2)),n)
        override $(1) = echo "*** FATAL BUILD ERROR: "$(3) >&2; exit 1;
        cc-option := n
    endif
endef

define absolutify_xen_root
    case "$(XEN_ROOT)" in                                          \
    /*) XEN_ROOT=$(XEN_ROOT) ;;                                    \
    *)  xen_root_lhs=`pwd`;                                        \
        xen_root_rhs=$(XEN_ROOT)/;                                 \
        while [ "x$${xen_root_rhs#../}" != "x$$xen_root_rhs" ]; do \
            xen_root_rhs="$${xen_root_rhs#../}";                   \
            xen_root_rhs="$${xen_root_rhs#/}";                     \
            xen_root_rhs="$${xen_root_rhs#/}";                     \
            xen_root_lhs="$${xen_root_lhs%/*}";                    \
        done;                                                      \
        XEN_ROOT="$$xen_root_lhs/$$xen_root_rhs" ;;                \
    esac;                                                          \
    export XEN_ROOT
endef

define buildmakevars2shellvars
    PREFIX="$(PREFIX)";                                            \
    XEN_SCRIPT_DIR="$(XEN_SCRIPT_DIR)";                            \
    export PREFIX;                                                 \
    export XEN_SCRIPT_DIR
endef

buildmakevars2file = $(eval $(call buildmakevars2file-closure,$(1)))
define buildmakevars2file-closure
    .PHONY: genpath
    genpath:
	rm -f $(1);                                                    \
	echo "SBINDIR=\"$(SBINDIR)\"" >> $(1);                         \
	echo "BINDIR=\"$(BINDIR)\"" >> $(1);                           \
	echo "LIBEXEC=\"$(LIBEXEC)\"" >> $(1);                         \
	echo "LIBDIR=\"$(LIBDIR)\"" >> $(1);                           \
	echo "SHAREDIR=\"$(SHAREDIR)\"" >> $(1);                       \
	echo "PRIVATE_BINDIR=\"$(PRIVATE_BINDIR)\"" >> $(1);           \
	echo "XENFIRMWAREDIR=\"$(XENFIRMWAREDIR)\"" >> $(1);           \
	echo "XEN_CONFIG_DIR=\"$(XEN_CONFIG_DIR)\"" >> $(1);           \
	echo "XEN_SCRIPT_DIR=\"$(XEN_SCRIPT_DIR)\"" >> $(1)
endef

ifeq ($(debug),y)
CFLAGS += -g
endif

CFLAGS += -fno-strict-aliasing

CFLAGS += -std=gnu99

CFLAGS += -Wall -Wstrict-prototypes

# -Wunused-value makes GCC 4.x too aggressive for my taste: ignoring the
# result of any casted expression causes a warning.
CFLAGS += -Wno-unused-value

$(call cc-option-add,HOSTCFLAGS,HOSTCC,-Wdeclaration-after-statement)
$(call cc-option-add,CFLAGS,CC,-Wdeclaration-after-statement)

LDFLAGS += $(foreach i, $(EXTRA_LIB), -L$(i)) 
CFLAGS += $(foreach i, $(EXTRA_INCLUDES), -I$(i))

# Enable XSM security module.  Enabling XSM requires selection of an 
# XSM security module (FLASK_ENABLE or ACM_SECURITY).
XSM_ENABLE ?= n
FLASK_ENABLE ?= n
ACM_SECURITY ?= n

XEN_EXTFILES_URL=http://xenbits.xensource.com/xen-extfiles
# All the files at that location were downloaded from elsewhere on
# the internet.  The original download URL is preserved as a comment
# near the place in the Xen Makefiles where the file is used.

# GIT protocol can be faster than HTTP, if your firewall lets it through.
# QEMU_REMOTE=git://xenbits.xensource.com/qemu-xen-unstable.git
QEMU_REMOTE=http://xenbits.xensource.com/git-http/qemu-xen-unstable.git

# Specify which qemu-dm to use. This may be `ioemu' to use the old
# Mercurial in-tree version, or a local directory, or a git URL.
# CONFIG_QEMU ?= ../qemu-xen.git
CONFIG_QEMU ?= $(QEMU_REMOTE)

QEMU_TAG ?= f72b6e0ffc3bb84d4442c5a7493bffbdce2a4468
# Wed Nov 4 17:07:57 2009 +0000
# fix drive name parsing (any_hdN erroneous local declaration)

OCAML_XENSTORED_REPO=http://xenbits.xensource.com/ext/xen-ocaml-tools.hg

# Build OCAML version of xenstored instead of the in-tree C version?
# This will cause $(OCAML_XENSTORED_REPO) to be cloned.
CONFIG_OCAML_XENSTORED ?= n

# Optional components
XENSTAT_XENTOP     ?= y
VTPM_TOOLS         ?= n
LIBXENAPI_BINDINGS ?= n
PYTHON_TOOLS       ?= y
CONFIG_MINITERM    ?= n
CONFIG_LOMOUNT     ?= n

-include $(XEN_ROOT)/.config

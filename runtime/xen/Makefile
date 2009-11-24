#
# Grand Unified Makefile for Mirage, based on the Xen one.
#

# Default target must appear before any include lines
.PHONY: all
all: core
	@:

export XEN_ROOT=$(CURDIR)
include Config.mk

SUBARCH := $(subst x86_32,i386,$(XEN_TARGET_ARCH))
export XEN_TARGET_ARCH SUBARCH XEN_SYSTYPE

core:
	make -C stubdom c-stubdom

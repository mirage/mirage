include $(XEN_ROOT)/config/StdGNU.mk

# You may use wildcards, e.g. KERNELS=*2.6*
ifeq (ia64,$(XEN_TARGET_ARCH))
KERNELS ?= linux-2.6-xen
else
KERNELS ?= linux-2.6-pvops
endif

XKERNELS := $(foreach kernel, $(KERNELS), \
              $(patsubst buildconfigs/mk.%,%, \
                $(wildcard buildconfigs/mk.$(kernel))) )

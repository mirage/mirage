# Set mini-os root path, used in mini-os.mk.
MINI-OS_ROOT=$(XEN_ROOT)/extras/mini-os
export MINI-OS_ROOT

libc = $(stubdom)

XEN_INTERFACE_VERSION := 0x00030205
export XEN_INTERFACE_VERSION

# Try to find out the architecture family TARGET_ARCH_FAM.
# First check whether x86_... is contained (for x86_32, x86_32y, x86_64).
# If not x86 then use $(XEN_TARGET_ARCH) -> for ia64, ...
ifeq ($(findstring x86_,$(XEN_TARGET_ARCH)),x86_)
TARGET_ARCH_FAM = x86
else
TARGET_ARCH_FAM = $(XEN_TARGET_ARCH)
endif

# The architecture family directory below mini-os.
TARGET_ARCH_DIR := arch/$(TARGET_ARCH_FAM)

# Export these variables for possible use in architecture dependent makefiles.
export TARGET_ARCH_DIR
export TARGET_ARCH_FAM

# This is used for architecture specific links.
# This can be overwritten from arch specific rules.
ARCH_LINKS =

# The path pointing to the architecture specific header files.
ARCH_INC := $(TARGET_ARCH_FAM)

# For possible special header directories.
# This can be overwritten from arch specific rules.
EXTRA_INC = $(ARCH_INC)	

# Include the architecture family's special makerules.
# This must be before include minios.mk!
include $(MINI-OS_ROOT)/$(TARGET_ARCH_DIR)/arch.mk

extra_incl := $(foreach dir,$(EXTRA_INC),-isystem $(CURDIR)/$(MINI-OS_ROOT)/include/$(dir))

DEF_CPPFLAGS += -isystem $(CURDIR)/$(MINI-OS_ROOT)/include
DEF_CPPFLAGS += -D__MINIOS__

ifeq ($(libc),y)
DEF_CPPFLAGS += -DHAVE_LIBC
DEF_CPPFLAGS += -isystem $(CURDIR)/$(MINI-OS_ROOT)/include/posix
DEF_CPPFLAGS += -isystem $(CURDIR)/$(XEN_ROOT)/tools/xenstore
endif

ifneq ($(LWIPDIR),)
lwip=y
DEF_CPPFLAGS += -DHAVE_LWIP
DEF_CPPFLAGS += -isystem $(LWIPDIR)/src/include
DEF_CPPFLAGS += -isystem $(LWIPDIR)/src/include/ipv4
endif

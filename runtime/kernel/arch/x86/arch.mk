#
# Architecture special makerules for x86 family
# (including x86_32, x86_32y and x86_64).
#

ifeq ($(XEN_TARGET_ARCH),x86_32)
ARCH_CFLAGS  := -m32 -march=i686
ARCH_LDFLAGS := -m elf_i386
ARCH_ASFLAGS := -m32
EXTRA_INC += $(TARGET_ARCH_FAM)/$(XEN_TARGET_ARCH)
EXTRA_SRC += arch/$(EXTRA_INC)
endif

ifeq ($(XEN_TARGET_ARCH),x86_64)
ARCH_CFLAGS := -m64 -mno-red-zone -fno-reorder-blocks
ARCH_CFLAGS += -fno-asynchronous-unwind-tables
ARCH_ASFLAGS := -m64
ARCH_LDFLAGS := -m elf_x86_64
EXTRA_INC += $(TARGET_ARCH_FAM)/$(XEN_TARGET_ARCH)
EXTRA_SRC += arch/$(EXTRA_INC)
endif


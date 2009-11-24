#
# The file contains the common make rules for building mini-os.
#

debug = y

# Define some default flags.
# NB. '-Wcast-qual' is nasty, so I omitted it.
DEF_CFLAGS += -fno-builtin -Wall -Werror -Wredundant-decls -Wno-format -Wno-redundant-decls
DEF_CFLAGS += $(call cc-option,$(CC),-fno-stack-protector,)
DEF_CFLAGS += $(call cc-option,$(CC),-fgnu89-inline)
DEF_CFLAGS += -Wstrict-prototypes -Wnested-externs -Wpointer-arith -Winline
DEF_CPPFLAGS += -D__XEN_INTERFACE_VERSION__=$(XEN_INTERFACE_VERSION)

DEF_ASFLAGS += -D__ASSEMBLY__
DEF_LDFLAGS +=

ifeq ($(debug),y)
DEF_CFLAGS += -g
#DEF_CFLAGS += -DMM_DEBUG
#DEF_CFLAGS += -DFS_DEBUG
#DEF_CFLAGS += -DLIBC_DEBUG
DEF_CFLAGS += -DGNT_DEBUG
DEF_CFLAGS += -DGNTMAP_DEBUG
else
DEF_CFLAGS += -O3
endif

# Make the headers define our internal stuff
DEF_CFLAGS += -D__INSIDE_MINIOS__

# Build the CFLAGS and ASFLAGS for compiling and assembling.
# DEF_... flags are the common mini-os flags,
# ARCH_... flags may be defined in arch/$(TARGET_ARCH_FAM/rules.mk
CFLAGS := $(DEF_CFLAGS) $(ARCH_CFLAGS)
CPPFLAGS := $(DEF_CPPFLAGS) $(ARCH_CPPFLAGS)
ASFLAGS := $(DEF_ASFLAGS) $(ARCH_ASFLAGS)
LDFLAGS := $(DEF_LDFLAGS) $(ARCH_LDFLAGS)

# Special build dependencies.
# Rebuild all after touching this/these file(s)
EXTRA_DEPS = $(MINI-OS_ROOT)/minios.mk \
		$(MINI-OS_ROOT)/$(TARGET_ARCH_DIR)/arch.mk

# Find all header files for checking dependencies.
HDRS := $(wildcard $(MINI-OS_ROOT)/include/*.h)
HDRS += $(wildcard $(MINI-OS_ROOT)/include/xen/*.h)
HDRS += $(wildcard $(ARCH_INC)/*.h)
# For special wanted header directories.
extra_heads := $(foreach dir,$(EXTRA_INC),$(wildcard $(dir)/*.h))
HDRS += $(extra_heads)

# Add the special header directories to the include paths.
override CPPFLAGS := $(CPPFLAGS) $(extra_incl)

# The name of the architecture specific library.
# This is on x86_32: libx86_32.a
# $(ARCH_LIB) has to built in the architecture specific directory.
ARCH_LIB_NAME = $(XEN_TARGET_ARCH)
ARCH_LIB := lib$(ARCH_LIB_NAME).a

# This object contains the entrypoint for startup from Xen.
# $(HEAD_ARCH_OBJ) has to be built in the architecture specific directory.
HEAD_ARCH_OBJ := $(XEN_TARGET_ARCH).o
HEAD_OBJ := $(OBJ_DIR)/$(TARGET_ARCH_DIR)/$(HEAD_ARCH_OBJ)


$(OBJ_DIR)/%.o: %.c $(HDRS) Makefile $(EXTRA_DEPS)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.S $(HDRS) Makefile $(EXTRA_DEPS)
	$(CC) $(ASFLAGS) $(CPPFLAGS) -c $< -o $@





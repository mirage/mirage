#
# x86 architecture specific makefiles.
# It's is used for x86_32, x86_32y and x86_64
#

XEN_ROOT = ../../../..
include $(XEN_ROOT)/Config.mk
include ../../Config.mk

# include arch.mk has to be before mini-os.mk!

include arch.mk
include ../../minios.mk

# Sources here are all *.c *.S without $(XEN_TARGET_ARCH).S
# This is handled in $(HEAD_ARCH_OBJ)
ARCH_SRCS := $(wildcard *.c)

# The objects built from the sources.
ARCH_OBJS := $(patsubst %.c,$(OBJ_DIR)/%.o,$(ARCH_SRCS))

all: $(OBJ_DIR)/$(ARCH_LIB)

# $(HEAD_ARCH_OBJ) is only build here, needed on linking
# in ../../Makefile.
$(OBJ_DIR)/$(ARCH_LIB): $(ARCH_OBJS) $(OBJ_DIR)/$(HEAD_ARCH_OBJ)
	$(AR) rv $(OBJ_DIR)/$(ARCH_LIB) $(ARCH_OBJS)

clean:
	rm -f $(OBJ_DIR)/$(ARCH_LIB) $(ARCH_OBJS) $(OBJ_DIR)/$(HEAD_ARCH_OBJ)


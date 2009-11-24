#
# Special makefile for ia64.
#

XEN_ROOT = ../../../..
include $(XEN_ROOT)/Config.mk

include ../../Config.mk

include arch.mk
include ../../minios.mk

ARCH_SRCS := sal.c
ARCH_SRCS += efi.c
ARCH_SRCS += time.c
ARCH_SRCS += ivt.S
ARCH_SRCS += fw.S
ARCH_SRCS += common.c
ARCH_SRCS += time.c
ARCH_SRCS += mm.c
ARCH_SRCS += debug.c
ARCH_SRCS += sched.c
ARCH_SRCS += xencomm.c
ARCH_SRCS += __umoddi3.S
ARCH_SRCS += __udivdi3.S
ARCH_SRCS += __divdi3.S

ARCH_OBJS := sal.o
ARCH_OBJS += efi.o
ARCH_OBJS += time.o
ARCH_OBJS += ivt.o
ARCH_OBJS += fw.o
ARCH_OBJS += common.o
ARCH_OBJS += time.o
ARCH_OBJS += mm.o
ARCH_OBJS += debug.o
ARCH_OBJS += sched.o
ARCH_OBJS += xencomm.o
ARCH_OBJS += __umoddi3.o
ARCH_OBJS += __udivdi3.o
ARCH_OBJS += __udivsi3.o
ARCH_OBJS += __divdi3.o
ARCH_OBJS := $(addprefix $(OBJ_DIR)/,$(ARCH_OBJS))

GEN_OFF_SRC := gen_off.c
GEN_OFF_ASM := gen_off.s
GEN_OFF_H   := $(MINI-OS_ROOT)/include/$(ARCH_INC)/offsets.h

all: $(OBJ_DIR)/$(ARCH_LIB)

$(GEN_OFF_ASM): $(GEN_OFF_SRC)
	$(CC) -S -o $@ $(CPPFLAGS) $<

$(GEN_OFF_H): $(GEN_OFF_ASM)
	sed -ne "/^->/ {s/->/#define /; p}" < $< > $@

$(OBJ_DIR)/$(ARCH_LIB): $(GEN_OFF_H) $(ARCH_OBJS) $(OBJ_DIR)/$(HEAD_ARCH_OBJ)
	$(AR) rv $(ARCH_LIB) $(ARCH_OBJS)

clean:
	rm -f $(OBJ_DIR)/$(ARCH_LIB) $(ARCH_OBJS) $(OBJ_DIR)/$(HEAD_ARCH_OBJ)
	rm -f $(GEN_OFF_ASM)
	rm -f $(GEN_OFF_H)


ARCH_CFLAGS := -mfixed-range=f2-f5,f12-f15,f32-f127 -mconstant-gp
ARCH_CFLAGS += -O2
ARCH_ASFLAGS := -x assembler-with-cpp
ARCH_ASFLAGS += -mfixed-range=f2-f5,f12-f15,f32-f127 -fomit-frame-pointer
ARCH_ASFLAGS += -fno-builtin -fno-common -fno-strict-aliasing -mconstant-gp

ARCH_LDFLAGS = -warn-common


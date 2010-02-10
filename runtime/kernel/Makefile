VPATH=.:console:lib:sys:xenbus:arch/x86

OBJDIR=./obj

CORE_SRC = $(wildcard *.c)
LIB_SRC  = hash_functions.c hash_table.c sqlite3.c sqlite3_xen.c stack_chk_fail.c sys.c xs.c
ARCH_SRC = x86_ioremap.c x86_sched.c x86_time.c x86_mm.c x86_setup.c x86_traps.c
CONSOLE_SRC = console.c xencons_ring.c
XB_SRC = xenbus.c

LDFLAGS = -L$(shell pwd)/../inst-x86_64/lib
EXTRA_LIB = -lc -lm

AS_OBJ = x86_64.o
ALL_SRC = $(CORE_SRC) $(LIB_SRC) $(ARCH_SRC) $(CONSOLE_SRC) $(XB_SRC)
ALL_OBJ = $(ALL_SRC:%.c=$(OBJDIR)/%.o) $(AS_OBJ)

.PHONY: all
all: $(OBJDIR)/mirage-app

$(OBJDIR):
	mkdir -p $(OBJDIR)

PWD = $(shell pwd)
BASEINC = $(PWD)/..
GCC_INSTALL = $(shell LANG=C gcc -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p')
CFLAGS += -nostdinc -std=gnu99
CFLAGS += -isystem $(GCC_INSTALL)include
CFLAGS += -isystem $(BASEINC)/dietlibc/include
CFLAGS += -isystem $(BASEINC)/include 
CFLAGS += -isystem $(PWD)/include 
CFLAGS += -isystem $(PWD)/include/x86 
CFLAGS += -isystem $(PWD)/include/x86/x86_64
CFLAGS += -D__XEN_INTERFACE_VERSION__=0x00030205
CFLAGS += -D__INSIDE_MINIOS__

ASFLAGS += -D__ASSEMBLY__
ASFLAGS += $(CFLAGS)

$(OBJDIR)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJDIR)/%.o: %.S
	$(CC) $(ASFLAGS) -c -o $@ $<

LD ?= ld
OBJCOPY ?= objcopy

$(OBJDIR)/mirage-app: $(OBJDIR) $(ALL_OBJ)
	$(LD) -r $(ALL_OBJ) $(LDFLAGS) $(EXTRA_LIB) -o $@.o
	$(OBJCOPY) -w -G xenos_* -G _start $@.o $@.o
	$(LD) -T arch/x86/minios-x86_64.lds $@.o -o $@

clean:
	rm -rf $(OBJDIR)

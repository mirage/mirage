VPATH=.:ocaml:console:lib:sys:xenbus:arch/x86

OBJDIR=./obj

CORE_SRC = $(wildcard *.c)
LIB_SRC  = hash_functions.c hash_table.c stack_chk_fail.c sys.c
ARCH_SRC = x86_ioremap.c x86_time.c x86_mm.c x86_setup.c x86_traps.c
CONSOLE_SRC = console.c
CAML_SRC = domain.c exit.c gettimeofday.c mmap_stubs.c xb_stubs.c ring_stubs.c xs_ring_stubs.c gnttab_stubs.c netfront_stubs.c

LDFLAGS = -L$(shell pwd)/../inst-x86_64/lib

AS_OBJ = $(OBJDIR)/x86_64.o
ALL_SRC = $(CORE_SRC) $(LIB_SRC) $(ARCH_SRC) $(CONSOLE_SRC)
ALL_OBJ = $(AS_OBJ) $(ALL_SRC:%.c=$(OBJDIR)/%.o)
CAML_OBJ = $(CAML_SRC:%.c=$(OBJDIR)/%.o)

.PHONY: all
all: $(OBJDIR)/mirage-os.gz

PWD = $(shell pwd)
BASEINC = $(PWD)/..

$(OBJDIR):
	mkdir -p $(OBJDIR)

GCC_INSTALL = $(shell LANG=C gcc -print-search-dirs | sed -n -e 's/install: \(.*\)/\1/p')
CFLAGS += -nostdinc -std=gnu99 -m64 -mno-red-zone -fno-reorder-blocks
CFLAGS += -isystem $(GCC_INSTALL)include
CFLAGS += -isystem $(BASEINC)/include 
CFLAGS += -isystem $(BASEINC)/include/mini-os
CFLAGS += -isystem $(BASEINC)/include/mini-os/x86 
CFLAGS += -isystem $(BASEINC)/include/mini-os/x86/x86_64
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
LDLIBS = -lmiragerun_xen $(CAML_OBJ) -lc -lm

$(OBJDIR)/mirage-os: $(OBJDIR) $(ALL_OBJ) $(CAML_OBJ) $(APP_LIB)
	$(LD) -d -nostdlib -m elf_x86_64 -T arch/x86/minios-x86_64.lds $(LDFLAGS) $(EXTRA_LIB) $(ALL_OBJ) $(APP_LIB) $(LDLIBS) -o $@

$(OBJDIR)/mirage-os.gz: $(OBJDIR)/mirage-os
	gzip -c -9 $< > $@

clean:
	rm -rf $(OBJDIR)

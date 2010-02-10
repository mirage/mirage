VPATH=.:lib:sys

OBJDIR=./obj

CORE_SRC = blkfront.c gntmap.c hypervisor.c main.c netfront.c events.c \
	   gnttab.c kernel.c mm.c sched.c
LIB_SRC  = hash_functions.c hash_table.c sqlite3.c sqlite3_xen.c stack_chk_fail.c sys.c xs.c

CORE_OBJ = $(CORE_SRC:%.c=$(OBJDIR)/%.o)
LIB_OBJ = $(LIB_SRC:%.c=$(OBJDIR)/%.o)
ALL_OBJ =  $(CORE_OBJ) $(LIB_OBJ)

.PHONY: all
all: $(OBJDIR) $(ALL_OBJ)

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

$(OBJDIR)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -rf $(OBJDIR)

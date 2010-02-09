# local "test" make file

CC  = $(CROSS)gcc
DCC = diet $(CC)

SRC = $(wildcard *.c) # test/test.c
OBJ = _dl_jump.o $(SRC:.c=.o)

#CFLAGS = -Wall -D__OD_CLEAN_ROOM -DNODIETREF -fPIC -g -O
#CFLAGS = -Wall -O2 -Bsymbolic -D__OD_CLEAN_ROOM -DNODIETREF -fPIC -frerun-loop-opt -fschedule-insns2 $(DEB)
CFLAGS = -Wall -g -O -I.. -isystem ../include -Bsymbolic -D__OD_CLEAN_ROOM -DNODIETREF -fPIC -frerun-loop-opt -fschedule-insns2 $(DEB)
# -fomit-frame-pointer

%.o : %.S
	$(DCC) $(CFLAGS) -c -o $@ $^

%.o : %.c
	$(DCC) $(CFLAGS) -c -o $@ $^

it: t.out

a.out: t.out
	$(CROSS)gcc -O -g test/a.c t.out -L/opt/diet/lib-i386 -lc -lgcc -o $@ -Wl,-dynamic-linker=`pwd`/t.out -nostdlib

t.out: _dl_main.o
	$(CROSS)ld -shared -o $@ $? -soname=libdl.so -Bsymbolic

all: test.out libdl.a

libdl.a: $(OBJ)
	ar cru $@ $^

test.g: test/test.c
	gcc -o $@ $^ -ldl

test.out: $(OBJ) test/test.o
	diet gcc -o $@ $^

clean:
	$(RM) *.o *.a *.out *~ # *.so

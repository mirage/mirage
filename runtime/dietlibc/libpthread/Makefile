all: libpthread.a

M=$(shell ../findcflags.sh $(CC))

ARCH=$(shell uname -m | sed 's/i[4-9]86/i386/')

CFLAGS= -g #-pipe -O -march=k6
CFLAGS= -pipe
CROSS=

CC=gcc

VPATH=../$(ARCH)/

PTHREAD_OBJS = __testandset.o $(patsubst %.c,%.o,$(wildcard pthread_*.c))

TESTS = $(patsubst %.c,%,$(wildcard test-*.c))

%.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $?

#include ../$(ARCH)/Makefile.add

ifeq ($(CFLAGS),-pipe)
CFLAGS+= -O2 -fomit-frame-pointer
endif

CFLAGS += -W -Wall
#CFLAGS += -fPIC

CFLAGS += -I. -I.. -I../include -Wall


PWD=$(shell pwd)

.SUFFIXES:
.SUFFIXES: .S .c

.PHONY: clean tests test.out

% :: %,v

%.o: %.S
	$(CROSS)$(CC) -I. -Iinclude $(CFLAGS) -c $<

%.o: %.c
	$(CROSS)$(CC) -I. -Iinclude $(CFLAGS) -c $<
#	$(CROSS)strip -x -R .comment -R .note $@

libpthread.a: $(PTHREAD_OBJS)
	$(CROSS)ar cr $@ $^

libpthread.so: libpthread.a
	$(CROSS)ld -whole-archive -shared -o $@ $^


clean: tests-clean
	$(RM) *.o *.a *.so *.out *~ *.oa

exports: libpthread.a
	nm -g libpthread.a | grep -w T | awk '{ print $$3 }' | sort -u > exports

.PHONY: test.out

test.out: test.o libpthread.a $(LIBS)
	$(CROSS)$(CC) -g $(CFLAGS) -nostdlib ../bin-$(ARCH)/start.o ../bin-$(ARCH)/dyn_start.o -o $@ $^ ../bin-$(ARCH)/dietlibc.a -lgcc ../bin-$(ARCH)/dyn_stop.o

tests: tests-clean $(TESTS)

tests-clean:
	$(RM) $(TESTS)

# libpthread.a
pthread.oa: $(PTHREAD_OBJS)
	ld -r -o $@ $(patsubst pthread_errno.o,,$^)

$(TESTS): pthread.oa
	$(CROSS)$(CC) -g $(CFLAGS) -nostdlib ../bin-$(ARCH)/start.o ../bin-$(ARCH)/dyn_start.o -o $@ $@.c $^ ../bin-$(ARCH)/dietlibc.a -lgcc ../bin-$(ARCH)/dyn_stop.o

.PHONY: sparc ppc mips arm alpha i386

sparc ppc alpha i386:
	$(MAKE) ARCH=$@ CROSS=$@-linux- all t libdietc.so

mips arm:
	$(MAKE) ARCH=$@ CROSS=$@-linux- all t libdietc.so


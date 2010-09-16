# build runtime library for unix
ROOTDIR=../..
include $(ROOTDIR)/mk/base.mk

CFLAGS=-I "$(shell ocamlc -where)" -Wall

SOURCES=evtchn_stubs console_stubs clock_stubs tap_stubs tap_stubs_$(OS) time_stubs socket_stubs
CS=$(SOURCES:%=%.c)
OBJS=$(SOURCES:%=%.o)
LIB=libmirage_unix.a

$(LIB): $(OBJS)
	ar rc $@ $^

%.o: %.c
	$(CC) -c -O2 $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -f *.o *.a

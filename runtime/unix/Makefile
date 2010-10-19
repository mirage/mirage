# build runtime library for unix
ROOTDIR=../..
include $(ROOTDIR)/mk/base.mk

CFLAGS=-I "$(shell ocamlc -where)" -Wall

SOURCES=evtchn_stubs console_stubs clock_stubs tap_stubs tap_stubs_$(OS) time_stubs socket_stubs page_stubs
CS=$(SOURCES:%=%.c)
OBJS=$(SOURCES:%=%.o)
LIB=libmirage_unix.a
EVLIB=libev/.libs/libev.a

.PHONY: all
all: $(LIB) $(EVLIB)
	@ :

libev/Makefile:
	cd libev && ./configure --enable-static --disable-shared

$(EVLIB): libev/Makefile
	cd libev && $(MAKE)

$(LIB): $(OBJS)
	ar rc $@ $^

%.o: %.c
	$(CC) -c -O2 $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	cd libev && $(MAKE) clean || true
	rm -f *.o *.a

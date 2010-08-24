ROOTDIR=$(abspath ../../..)
MODE ?= xen
include $(ROOTDIR)/mk/$(MODE).mk

OBJDIR = $(CURDIR)/obj-$(MODE)
OUT = $(OBJDIR)/libmiragerun_$(MODE).a

ASMRUN_debug = libasmrund.a
ASMRUN_normal = libasmrun.a
ASMRUN = debug
ASMRUNLIB = $(ASMRUN_$(ASMRUN))

.PHONY: all
all: $(OUT)
	@ :

$(OBJDIR)/.stamp:
	cp -R ocaml/ $(OBJDIR)/
	@touch $@

$(OUT): $(OBJDIR)/asmrun/$(ASMRUNLIB) $(OBJDIR)/otherlibs/bigarray/libbigarray.a
	cp $< $@
	ar rvs $@ $(OBJDIR)/otherlibs/bigarray/bigarray_stubs.o $(OBJDIR)/otherlibs/bigarray/mmap_unix.o

$(OBJDIR)/asmrun/$(ASMRUNLIB): $(OBJDIR)/.stamp
	cd $(OBJDIR) && ./configure -no-pthread -no-shared-libs -no-tk -no-curses \
                -cc "$(CC) $(CFLAGS) -U_FORTIFY_SOURCE"
	$(foreach i,$(HAS_NOT),sed -i -e 's,^\(#define $(i)\),//\1,' $(OBJDIR)/config/s.h ; )
	cp $(OBJDIR)/config/m-xen.h $(OBJDIR)/config/m.h
	cp $(OBJDIR)/config/s-xen.h $(OBJDIR)/config/s.h
	cd $(OBJDIR)/asmrun && $(MAKE) -f Makefile.xen SYSTEM=$(MODE) $(ASMRUNLIB)

$(OBJDIR)/otherlibs/bigarray/libbigarray.a: $(OBJDIR)/.stamp
	cd $(OBJDIR)/otherlibs/bigarray && $(MAKE) SYSTEM=$(MODE) bigarray_stubs.o mmap_unix.o && ar rvs libbigarray.a bigarray_stubs.o mmap_unix.o

clean:
	rm -rf $(OBJDIR)

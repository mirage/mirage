ROOTDIR=$(abspath ../..)
include $(ROOTDIR)/mk/$(MODE).mk

HAS_NOT := HAS_IPV6 HAS_INET_ATON POSIX_SIGNALS HAS_GETRUSAGE HAS_STACK_OVERFLOW_DETECTION HAS_TIMES
MODE ?= unknown

OBJDIR = $(CURDIR)/obj-$(MODE)
OUT = $(OBJDIR)/libmiragerun_$(MODE).a

ASMRUN_debug = libasmrund.a
ASMRUN_normal = libasmrun.a
ASMRUN = normal
ASMRUNLIB = $(ASMRUN_$(ASMRUN))

.PHONY: all
all: $(OUT)
	@ :

$(OBJDIR)/.stamp:
	cp -R ocaml/ $(OBJDIR)/
	@touch $@

$(OUT): $(OBJDIR)/asmrun/$(ASMRUNLIB)
	cp $< $@

$(OBJDIR)/asmrun/$(ASMRUNLIB): $(OBJDIR)/.stamp
	cd $(OBJDIR) && ./configure -no-pthread -no-shared-libs -no-tk -no-curses \
                -cc "$(CC) $(CFLAGS) -U_FORTIFY_SOURCE"
	$(foreach i,$(HAS_NOT),sed -i -e 's,^\(#define $(i)\),//\1,' $(OBJDIR)/config/s.h ; )
	sed -i -e 's,Unix,$(MODE),g' $(OBJDIR)/config/s.h
	cd $(OBJDIR)/asmrun && $(MAKE) SYSTEM=$(MODE) $(ASMRUNLIB)

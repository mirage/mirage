ROOTDIR=$(abspath ../..)
include $(ROOTDIR)/mk/$(MODE).mk

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
	cp $(OBJDIR)/config/m-xen.h $(OBJDIR)/config/m.h
	cp $(OBJDIR)/config/s-xen.h $(OBJDIR)/config/s.h
	cd $(OBJDIR)/asmrun && $(MAKE) SYSTEM=$(MODE) $(ASMRUNLIB)

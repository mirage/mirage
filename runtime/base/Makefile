ROOTDIR=$(abspath ../..)
include $(ROOTDIR)/mk/$(MODE).mk

HAS_NOT := HAS_IPV6 HAS_INET_ATON POSIX_SIGNALS HAS_GETRUSAGE HAS_STACK_OVERFLOW_DETECTION HAS_TIMES
MODE ?= unknown

OUT = ../libmiragerun_$(MODE).a
OBJ = $(CURDIR)/obj-$(MODE)
LIBMIR = $(CURDIR)/mir

.PHONY: all
all: $(OUT)
	@ :

$(OBJ)/.stamp:
	cp -R ocaml/ $(OBJ)/
	@touch $@

$(OUT): $(OBJ)/asmrun/libasmrun.a $(LIBMIR)/obj-$(MODE)/libmir.a
	cp $(OBJ)/asmrun/libasmrun.a $@
	ar rc $@ $(LIBMIR)/obj-$(MODE)/*.o

$(OBJ)/asmrun/libasmrun.a: $(OBJ)/.stamp
	cd $(OBJ) && ./configure -no-pthread -no-shared-libs -no-tk -no-curses \
                -cc "$(CC) $(CFLAGS) -U_FORTIFY_SOURCE"
	$(foreach i,$(HAS_NOT),sed -i -e 's,^\(#define $(i)\),//\1,' $(OBJ)/config/s.h ; )
	sed -i -e 's,Unix,$(MODE),g' $(OBJ)/config/s.h
	cd $(OBJ)/asmrun && $(MAKE) SYSTEM=$(MODE) libasmrun.a

$(LIBMIR)/obj-$(MODE)/libmir.a:
	cd $(LIBMIR) && $(MAKE) MODE=$(MODE)

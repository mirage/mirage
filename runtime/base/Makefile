HAS_NOT := HAS_IPV6 HAS_INET_ATON POSIX_SIGNALS HAS_GETRUSAGE HAS_STACK_OVERFLOW_DETECTION HAS_TIMES

MODE ?= unknown

OUT = ../libmiragerun_$(MODE).a
OBJ = $(CURDIR)/obj-$(MODE)

.PHONY: all
all: $(OUT)
	@ :

$(OBJ)/.stamp:
	cp -rl ocaml/ $(OBJ)/
	@touch $@

$(OUT): $(OBJ)/asmrun/libasmrun.a
	cp $< $@

$(OBJ)/asmrun/libasmrun.a: $(OBJ)/.stamp
	cd $(OBJ) && ./configure -no-pthread -no-shared-libs -no-tk -no-curses \
                -cc "$(CC) -U_FORTIFY_SOURCE -fno-stack-protector"
	$(foreach i,$(HAS_NOT),sed -i 's,^\(#define $(i)\),//\1,' $(OBJ)/config/s.h ; )
	cd $(OBJ)/asmrun && $(MAKE) SYSTEM=$(MODE) libasmrun.a

HAS_NOT := HAS_IPV6 HAS_INET_ATON POSIX_SIGNALS HAS_GETRUSAGE HAS_STACK_OVERFLOW_DETECTION HAS_TIMES

OUT=../libmiragerun.a

.PHONY: all
all: $(OUT)
	@ :

$(OUT): ocaml/asmrun/libasmrun.a
	cp $< $@

ocaml/asmrun/libasmrun.a:
	cd ocaml && ./configure -no-pthread -no-shared-libs -no-tk -no-curses \
                -cc "$(CC) -U_FORTIFY_SOURCE -fno-stack-protector"
	$(foreach i,$(MINIOS_HASNOT),sed -i 's,^\(#define $(i)\),//\1,' ocaml/config/s.h ; )
	cd ocaml/asmrun && $(MAKE)

.PHONY: clean
clean:
	cd ocaml && $(MAKE) clean
	rm -f $(OUT) 

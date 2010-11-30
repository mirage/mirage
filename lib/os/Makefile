.PHONY: clean all depend

all: depend
	ocamlbuild all.otarget

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
depend: $(EVMAKE) $(EVLIB)
	ln -nfs tap_stubs_$(OS).c runtime_unix/tap_stubs_os.c
	ln -nfs ev_$(OS).c runtime_unix/ev_os.c

clean:
	ocamlbuild -clean

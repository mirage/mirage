.PHONY: clean all

LIB_UNIX=lib_unix/oS.cmxa
LIB_XEN=lib_xen/oS.cmxa
RUNTIME_UNIX=runtime_unix/libunixrun.a

TARGETS=$(LIB_UNIX) $(LIB_XEN) $(RUNTIME_UNIX)

.PHONY: all depend
all: depend
	ocamlbuild $(LIB_UNIX)
	ocamlbuild $(LIB_XEN)
	ocamlbuild $(RUNTIME_UNIX)

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')

depend: $(EVMAKE) $(EVLIB)
	ln -nfs tap_stubs_$(OS).c runtime_unix/tap_stubs_os.c
	ln -nfs ev_$(OS).c runtime_unix/ev_os.c

clean:
	ocamlbuild -clean

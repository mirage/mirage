PREFIX ?= _build/root
TARGETDIR=$(PREFIX)/mirage/os
OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')

.PHONY: clean all depend install
all: depend
	ocamlbuild all.otarget

depend: $(EVMAKE) $(EVLIB)
	ln -nfs tap_stubs_$(OS).c runtime_unix/tap_stubs_os.c
	ln -nfs ev_$(OS).c runtime_unix/ev_os.c

install:
	mkdir -p $(TARGETDIR)/xen $(TARGETDIR)/unix
	cp _build/unix/oS.cmi _build/unix/oS.cmxa _build/unix/os.a $(TARGETDIR)/unix
	cp _build/xen/oS.cmi _build/xen/oS.cmxa _build/xen/os.a $(TARGETDIR)/xen
	cp _build/runtime_unix/libunixrun.a _build/runtime_unix/main.o $(TARGETDIR)/unix

clean:
	ocamlbuild -clean
	rm -f runtime_unix/tap_stubs_os.c runtime_unix/ev_os.c

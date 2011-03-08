PREFIX ?= _build/root
TARGETDIR=$(PREFIX)/mirage/os
OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_INSTALL=install-xen
XEN_BUILD=xen.otarget
else
XEN_BUILD=
XEN_INSTALL=
endif

.PHONY: clean all depend install unix xen node
all: depend
	ocamlbuild $(JOBS) unix.otarget $(XEN_BUILD) node.otarget

unix: depend
	ocamlbuild $(JOBS) unix.otarget

xen:
	ocamlbuild $(JOBS) xen.otarget

node: depend
	ocamlbuild node.otarget

depend: $(EVMAKE) $(EVLIB) runtime_node/dummy_stubs.c
	ln -nfs tap_stubs_$(OS).c runtime_unix/tap_stubs_os.c
	ln -nfs ev_$(OS).c runtime_unix/ev_os.c

NODE_FILES=console activations clock time main istring lib/js
runtime_node/dummy_stubs.c: $(NODE_FILES:%=node/%.ml)
	(echo "#include <stdlib.h>"; \
	 echo "#include <stdio.h>"; \
	 echo "#define D(f) void f () { fprintf(stderr, \"Unimplemented Javascript primitive %s!\\\\n\", #f); exit(1); }"; \
	(sed -n -e 's/.*external[^"]*"\([^"%]*\)".*/D(\1)/p' $^ | \
	 sort | uniq)) \
	> $@

install: install-unix $(XEN_INSTALL) install-node
	@ :

install-unix:
	mkdir -p $(TARGETDIR)/unix
	cp _build/unix/oS.cmi _build/unix/oS.cmxa _build/unix/oS.a $(TARGETDIR)/unix
	cp _build/runtime_unix/libunixrun.a _build/runtime_unix/main.o $(TARGETDIR)/unix

install-xen:
	mkdir -p $(TARGETDIR)/xen
	cp _build/xen/oS.cmi _build/xen/oS.cmxa _build/xen/oS.a $(TARGETDIR)/xen
	cp runtime_xen/kernel/mirage-x86_64.lds $(TARGETDIR)/xen/
	cp _build/runtime_xen/dietlibc/libdiet.a $(TARGETDIR)/xen/
	cp _build/runtime_xen/libm/libm.a $(TARGETDIR)/xen/
	cp _build/runtime_xen/ocaml/libocaml.a $(TARGETDIR)/xen/
	cp _build/runtime_xen/kernel/libxen.a $(TARGETDIR)/xen/
	cp _build/runtime_xen/kernel/libxencaml.a $(TARGETDIR)/xen/
	cp _build/runtime_xen/kernel/x86_64.o $(TARGETDIR)/xen/

install-node:
	mkdir -p $(TARGETDIR)/node
	cp _build/node/oS.cmi _build/node/oS.cma $(TARGETDIR)/node
	cp runtime_node/runtime.js $(TARGETDIR)/node
	cp runtime_node/mirage.js $(TARGETDIR)/node

clean:
	ocamlbuild -clean
	rm -f runtime_unix/tap_stubs_os.c runtime_unix/ev_os.c
	rm -f runtime_node/dummy_stubs.c

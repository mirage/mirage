PREFIX ?= _build/root
TARGETDIR=$(PREFIX)/mirage/os
OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

NODE = $(shell ocamlfind query js_of_ocaml 2>/dev/null)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_BUILD=xen
else
XEN_BUILD=
endif

ifeq ($(NODE),)
NODE_BUILD=
else
NODE_BUILD=node
endif

.PHONY: clean all depend unix xen node
all: unix $(XEN_BUILD) $(NODE_BUILD)
	@ :

unix: depend
	ocamlbuild $(JOBS) unix.otarget

xen:
	ocamlbuild $(JOBS) xen.otarget

node: depend
	NODE=$(NODE)
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

clean:
	ocamlbuild -clean
	rm -f runtime_unix/tap_stubs_os.c runtime_unix/ev_os.c
	rm -f runtime_node/dummy_stubs.c

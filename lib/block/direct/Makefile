.PHONY: clean all install

PREFIX ?= _build/root

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_INSTALL=install-xen
XEN_BUILD=xen
else
XEN_BUILD=
XEN_INSTALL=
endif

.PHONY: all install unix xen
all: $(XEN_BUILD)
	@ :

unix:
	env MIRAGEOS=unix ocamlbuild $(JOBS) block.cmxa

xen:
	env MIRAGEOS=xen ocamlbuild $(JOBS) block.cmxa

clean:
	ocamlbuild -clean


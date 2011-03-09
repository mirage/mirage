.PHONY: clean all install

PREFIX ?= _build/root

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

.PHONY: all install unix xen
all: unix $(XEN_BUILD)
	@ :

unix:
	env MIRAGEOS=unix ocamlbuild $(JOBS) net.cmxa

xen:
	env MIRAGEOS=xen ocamlbuild $(JOBS) net.cmxa

clean:
	ocamlbuild -clean


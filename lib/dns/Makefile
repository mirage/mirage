.PHONY: clean all unix-% xen-%

PREFIX ?= _build/root

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)
NODE = $(shell ocamlfind query js_of_ocaml 2>/dev/null)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_BUILD=xen-direct
else
XEN_BUILD=
endif

ifeq ($(NODE),)
NODE_BUILD=
else
NODE_BUILD=node-socket
endif

all: unix-direct unix-socket $(XEN_BUILD) $(NODE_BUILD)
	@ :

unix-%:
	env MIRAGEOS=unix MIRAGEFLOW=$* ocamlbuild $(JOBS) dns.cmxa

xen-%:
	env MIRAGEOS=xen MIRAGEFLOW=$* ocamlbuild $(JOBS) dns.cmxa

node-%:
	env MIRAGEOS=node MIRAGEFLOW=$* ocamlbuild $(JOBS) dns.cma

clean:
	ocamlbuild -clean


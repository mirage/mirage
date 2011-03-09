.PHONY: clean all unix-% xen-%

PREFIX ?= _build/root

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_BUILD=xen-direct
else
XEN_BUILD=
endif

all: unix-direct unix-socket $(XEN_BUILD) node-socket
	@ :

unix-%:
	env MIRAGEOS=unix MIRAGEFLOW=$* ocamlbuild $(JOBS) dns.cmxa

xen-%:
	env MIRAGEOS=xen MIRAGEFLOW=$* ocamlbuild $(JOBS) dns.cmxa

node-%:
	env MIRAGEOS=node MIRAGEFLOW=$* ocamlbuild $(JOBS) dns.cma

clean:
	ocamlbuild -clean


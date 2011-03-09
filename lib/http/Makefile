.PHONY: clean all unix-% xen-%

PREFIX ?= _build/root

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_BUILD=xen-direct
else
XEN_BUILD=
endif

all: unix-socket unix-direct $(XEN_BUILD) node-socket
	@ :

unix-%:
	env MIRAGEOS=unix MIRAGEFLOW=$* ocamlbuild $(JOBS) http.cmxa

xen-%:
	env MIRAGEOS=xen MIRAGEFLOW=$* ocamlbuild $(JOBS) http.cmxa

node-%:
	env MIRAGEOS=node MIRAGEFLOW=$* ocamlbuild $(JOBS) http.cma

clean:
	ocamlbuild -clean


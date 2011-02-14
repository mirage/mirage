.PHONY: clean all unix-% xen-%

PREFIX ?= _build/root

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_BUILD=xen-direct
else
XEN_BUILD=
endif

all: unix-socket
	@ :

unix-%:
	env MIRAGEOS=unix MIRAGEFLOW=$* ocamlbuild http.cmxa

xen-%:
	env MIRAGEOS=xen MIRAGEFLOW=$* ocamlbuild http.cmxa

clean:
	ocamlbuild -clean


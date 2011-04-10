.PHONY: all unix clean

JOBS ?= -j 4

all: unix-direct unix-socket

unix-direct:
	mkdir -p _build
	env MIRAGEOS=unix MIRAGEFLOW=direct ocamlbuild $(JOBS) unix.otarget

unix-socket:
	mkdir -p _build
	env MIRAGEOS=unix MIRAGEFLOW=socket ocamlbuild $(JOBS) unix.otarget

xen-direct:
	mkdir -p _build
	env MIRAGEOS=unix MIRAGEFLOW=direct ocamlbuild $(JOBS) xen.otarget

clean:
	ocamlbuild -clean

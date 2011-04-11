.PHONY: all unix clean

JOBS ?= -j 4
OFLAGS ?= -classic-display

all: unix-direct unix-socket

unix-direct:
	@mkdir -p _build
	@env MIRAGEOS=unix MIRAGEFLOW=direct ocamlbuild $(OFLAGS) $(JOBS) unix.otarget

unix-socket:
	@mkdir -p _build
	@env MIRAGEOS=unix MIRAGEFLOW=socket ocamlbuild $(OFLAGS) $(JOBS) unix.otarget

xen-direct:
	@mkdir -p _build
	@env MIRAGEOS=xen MIRAGEFLOW=direct ocamlbuild $(JOBS) xen.otarget

clean:
	@ocamlbuild -clean

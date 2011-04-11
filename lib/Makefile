.PHONY: all unix clean

JOBS ?= -j 4
OFLAGS ?= -classic-display

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)
#NODE = $(shell ocamlfind query js_of_ocaml 2>/dev/null)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_BUILD=xen-direct
else
XEN_BUILD=
endif

all: unix-direct unix-socket $(XEN_BUILD)
	@ :

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

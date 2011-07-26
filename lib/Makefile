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

ifeq ($(NODE),)
NODE_BUILD=
else
NODE_BUILD=node-socket
endif

all: $(XEN_BUILD) unix-socket unix-direct
	@ :

unix-direct:
	@mkdir -p _build
	@env MIRAGEOS=unix MIRAGEFLOW=direct ocamlbuild $(OFLAGS) $(JOBS) unix.otarget

unix-socket:
	@mkdir -p _build
	@env MIRAGEOS=unix MIRAGEFLOW=socket ocamlbuild $(OFLAGS) $(JOBS) unix.otarget

xen-direct:
	@mkdir -p _build
	@env MIRAGEOS=xen MIRAGEFLOW=direct ocamlbuild $(OFLAGS) $(JOBS) xen.otarget

node-socket:
	@mkdir -p _build
	@env MIRAGEOS=node MIRAGEFLOW=socket ocamlbuild $(OFLAGS) $(JOBS) node.otarget

clean:
	@ocamlbuild -clean

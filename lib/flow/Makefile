.PHONY: clean all install

PREFIX ?= _build/root

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

ifeq ($(OS) $(ARCH),linux x86_64)
XEN_INSTALL=install-xen
XEN_BUILD=build-xen
else
XEN_BUILD=
XEN_INSTALL=
endif

TARGETS_xen=direct
TARGETS_unix=direct socket

.PHONY: all build-% install-%
all: build-unix $(XEN_BUILD)
	@ :

build-%:
	@for i in $(TARGETS_$*); do \
	  env MIRAGEOS=$* ocamlbuild $$i/flow.cmxa; done

install: install-unix $(XEN_INSTALL)
	@ :


install-%:
	TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/os/$*/flow; \
	for i in $(TARGETS_$*); do \
	  mkdir -p $$TARGETDIR/$$i; \
	  cp _build/$*/$$i/flow.cmxa $$TARGETDIR/$$i/; \
	  cp _build/$*/$$i/flow.a $$TARGETDIR/$$i; \
	  cp _build/$*/$$i/flow.cmi $$TARGETDIR/$$i; done

clean:
	ocamlbuild -clean

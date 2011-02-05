.PHONY: clean all install

PREFIX ?= _build/root

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

#off by default until working fully
ifeq ($(OS) $(ARCH),linux x86_64)
XEN_INSTALL=install-xen
XEN_BUILD=xen
else
XEN_BUILD=
XEN_INSTALL=
endif

.PHONY: all install unix xen
all: unix $(XEN_BUILD)
	@ :

unix:
	env MIRAGEOS=unix ocamlbuild net.cmxa

xen:
	env MIRAGEOS=xen ocamlbuild net.cmxa

install: install-unix $(XEN_INSTALL)
	@ :

install-%:
	TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/os/$*/net; \
	mkdir -p $$TARGETDIR; \
	cp _build/$*/net.cmxa $$TARGETDIR/; \
	cp _build/$*/net.a $$TARGETDIR/; \
	cp _build/$*/net.cmi $$TARGETDIR/

clean:
	ocamlbuild -clean


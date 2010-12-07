.PHONY: clean all install

PREFIX ?= _build/root
LIBS = nettypes mpl mlnet dns dhcp http

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)

#off by default until working fully
ifeq ($(OS) $(ARCH),linux x86_64xxx)
XEN_INSTALL=install-xen
XEN_BUILD=
else
XEN_BUILD=
XEN_INSTALL=
endif

.PHONY: all install unix xen
all: unix $(XEN_BUILD)
	@ :

unix:
	env MIRAGEOS=unix ocamlbuild all.otarget

xen:
	env MIRAGEOS=xen ocamlbuild all.otarget

install: install-unix $(XEN_INSTALL)
	@ :

install-%:
	TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/os/$*/net; \
	mkdir -p $$TARGETDIR; \
	for i in $(LIBS); do \
		cp _build/$*/$$i/$$i.cmi $$TARGETDIR/; \
		cp _build/$*/$$i/$$i.cmxa $$TARGETDIR/; \
		cp _build/$*/$$i/$$i.a $$TARGETDIR/; \
	done

clean:
	ocamlbuild -clean


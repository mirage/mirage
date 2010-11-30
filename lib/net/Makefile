.PHONY: clean all install

PREFIX ?= _build/root
OS ?= unix
LIBS = mpl mlnet dns dhcp http

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/os/$(OS)

all:
	ocamlbuild all.otarget

clean:
	ocamlbuild -clean

install:
	mkdir -p $(TARGETDIR)
	for i in $(LIBS); do cp _build/$(OS)/$$i/$$i.cmi _build/$(OS)/$$i/$$i.cmxa $(TARGETDIR)/; done

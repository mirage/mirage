.PHONY: clean all install

PREFIX ?= _build/root
OS ?= unix
LIBS = mpl mlnet dns dhcp http

TARGETDIR=$(DESTDIR)$(PREFIX)/mirage/os/$(OS)/net

all:
	ocamlbuild all.otarget

clean:
	ocamlbuild -clean

install:
	mkdir -p $(TARGETDIR)
	for i in $(LIBS); do \
		cp _build/$(OS)/$$i/$$i.cmi $(TARGETDIR)/; \
		cp _build/$(OS)/$$i/$$i.cmxa $(TARGETDIR)/; \
		cp _build/$(OS)/$$i/$$i.a $(TARGETDIR)/; \
	done

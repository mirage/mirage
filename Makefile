.PHONY: all configure build clean

BINDIR=/usr/local/bin
all:
	$(MAKE) configure
	$(MAKE) build

configure:
	obuild configure

build:
	obuild build

clean:
	obuild clean

install:
	cp dist/build/mirari/mirari $(DESTDIR)$(BINDIR)/mirari

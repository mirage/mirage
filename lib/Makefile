.PHONY: all

all:
	cd std && $(MAKE)
	cd os && $(MAKE)
	cd net && $(MAKE)

clean:
	cd std && $(MAKE) clean
	cd os && $(MAKE) clean
	cd net && $(MAKE) clean

PREFIX ?= ~/mir-inst
install:
	cd std && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install
	cd os && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install
	cd net && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install

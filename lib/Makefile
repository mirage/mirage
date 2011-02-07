.PHONY: all

all:
	cd std && $(MAKE)
	cd os && $(MAKE)
	cd net && $(MAKE)
	cd dyntype && $(MAKE)
#	cd cow && $(MAKE)
#	cd debugger && $(MAKE)

clean:
	cd std && $(MAKE) clean
	cd os && $(MAKE) clean
	cd net && $(MAKE) clean
	cd dyntype && $(MAKE) clean
#	cd cow && $(MAKE) clean
#	cd debugger && $(MAKE) clean

PREFIX ?= ~/mir-inst
install:
	cd std && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install
	cd os && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install
	cd net && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install
	cd flow && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install
	cd dyntype && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install
#	cd cow && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install
#	cd debugger && $(MAKE) DESTDIR=$(DESTDIR) PREFIX=$(PREFIX) install

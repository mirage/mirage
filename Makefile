OS ?= unix

PREFIX ?= /usr/local

ifneq "$(MIRAGE_OS)" ""
OS := $(MIRAGE_OS)
endif

.PHONY: all build clean install test
.DEFAULT: all

all:	build
	@ :

build:
	cd $(OS) && $(MAKE) all

clean:
	cd $(OS) && $(MAKE) clean

install:
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp scripts/mir-run $(DESTDIR)$(PREFIX)/bin/
	chmod a+x $(DESTDIR)$(PREFIX)/bin/mir-run
	cd $(OS) && $(MAKE) install

uninstall:
	cd $(OS) && $(MAKE) uninstall

test:
	cd $(OS) && $(MAKE) test

doc:
	cd $(OS) && $(MAKE) doc

unix-%:
	$(MAKE) OS=unix PREFIX=$(PREFIX) $*

xen-%:
	$(MAKE) OS=xen PREFIX=$(PREFIX) $*

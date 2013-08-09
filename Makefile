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

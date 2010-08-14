.PHONY: all clean
.DEFAULT: all

SUDO ?= sudo
export SUDO

DESTDIR ?=
export DESTDIR

PREFIX ?= /usr/local
export PREFIX

all:
	@if [ "`uname -m`" != "x86_64" ]; then echo "Must build on a 64-bit platform, usually Linux."; exit 1; fi
	@cd tools && $(MAKE) 
	@cd stdlib && $(MAKE)
	@cd runtime && $(MAKE)
	@cd syntax && $(MAKE)
	@cd lib && $(MAKE)

bootstrap:
	@cd tools && $(MAKE)
	@cd syntax && $(MAKE)

clean:
	@cd tools && $(MAKE) clean
	@cd stdlib && $(MAKE) clean
	@cd syntax && $(MAKE) clean
	@cd lib && $(MAKE) clean
	@cd runtime && $(MAKE) clean

install:
	@cd tools && $(MAKE) install
	@cd bin && $(MAKE) install
	@cd syntax && $(MAKE) install

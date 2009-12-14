.PHONY: all clean
.DEFAULT: all

SUDO ?= sudo
export SUDO

DESTDIR ?=
export DESTDIR

PREFIX ?= /usr/local
export PREFIX

all:
	@cd stdlib && $(MAKE)
	@cd runtime && $(MAKE)
	@cd syntax && $(MAKE)
	@cd lib && $(MAKE)

clean:
	@cd stdlib && $(MAKE) clean
	@cd syntax && $(MAKE) clean
	@cd lib && $(MAKE) clean
	@cd runtime && $(MAKE) clean

install:
	@cd stdlib && $(MAKE) install
	@cd syntax && $(MAKE) install
	@cd lib && $(MAKE) install
	@cd bin && $(MAKE) install

.PHONY: all clean tools
.DEFAULT: all
-include Makefile.config

SUDO ?= sudo
export SUDO

DESTDIR ?=
export DESTDIR

PREFIX ?= $(HOME)/mir-inst
export PREFIX

all:
	cd lib && $(MAKE)

tools:
	@cd tools && $(MAKE) tools

clean:
	@cd tools && $(MAKE) clean
	@cd lib && $(MAKE) clean
	@cd runtime && $(MAKE) clean

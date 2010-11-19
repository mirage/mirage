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
	@cd runtime && $(MAKE)
	@cd lib && $(MAKE) init
	ocamlbuild -Xs runtime,build,syntax,scripts,tools,doc,tests lib/unix.otarget
	cd _build && rm -f runtime && ln -s ../runtime .
	cd _build && rm -f syntax && ln -s ../syntax/_build syntax

bootstrap:
	@cd tools && $(MAKE) bootstrap

rebootstrap:
	@cd tools && $(MAKE) rebootstrap

tools:
	@cd tools && $(MAKE) tools
	@cd syntax && $(MAKE) && $(MAKE) install

clean:
	@cd tools && $(MAKE) clean
	@cd syntax && $(MAKE) clean
	@cd lib && $(MAKE) clean
	@cd runtime && $(MAKE) clean

install:
	@cd tools && $(MAKE) install
	@cd bin && $(MAKE) install
	@cd syntax && $(MAKE) install

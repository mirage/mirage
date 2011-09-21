.PHONY: all clean
.DEFAULT: all
-include Makefile.config

SUDO ?= sudo
export SUDO

DESTDIR ?=
export DESTDIR

PREFIX ?= $(HOME)/mir-inst
export PREFIX

JOBS=-j 6
export JOBS

all:
	@cd tools && $(MAKE)
	@cd syntax && $(MAKE)
	@cd lib && $(MAKE)

doc:
	@cd docs && $(MAKE) all
	@cd lib && $(MAKE) doc

install:
	@rm -rf _build
	@./assemble.sh
	@mkdir -p $(PREFIX)
	@cp -r _build/* $(PREFIX)/

clean:
	@cd syntax && $(MAKE) clean
	@cd lib && $(MAKE) clean
	@cd tools && $(MAKE) clean
	@rm -rf _build

install-el:
	@cd scripts/caml-mode && $(MAKE) install-el

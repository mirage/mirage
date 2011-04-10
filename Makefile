.PHONY: all clean tools
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

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ARCH = $(shell uname -m)
NODE = $(shell ocamlfind query js_of_ocaml 2>/dev/null)

WITH_XEN ?= n
ifeq ($(OS) $(ARCH),linux x86_64)
WITH_XEN ?= y
endif

WITH_UNIX ?= y

all: tools
	cd syntax && $(MAKE)
	cd lib && $(MAKE)

tools:
	@cd tools && $(MAKE) tools

install:
	rm -rf _build
	./assemble.sh
	mkdir -p $(PREFIX)
	cp -r _build/* $(PREFIX)/

clean:
	@cd syntax && $(MAKE) clean
	@cd tools && $(MAKE) clean
	@cd lib && $(MAKE) clean

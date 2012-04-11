.PHONY: all clean
.DEFAULT: all
-include Makefile.config

SUDO ?= sudo
export SUDO

DESTDIR ?=
export DESTDIR

PREFIX ?= $(HOME)/mir-inst
export PREFIX

JOBS ?= -j 6
export JOBS

MIR-DEBUG ?= 0
export MIR-DEBUG

all:
	@cd tools && $(MAKE)
	@cd syntax && $(MAKE)
	@cd lib && $(MAKE)

doc:
	@cd docs && $(MAKE) all
	@cd lib && $(MAKE) doc

doc-json:
	@./docs/_build/parse.native lib/_build/unix-socket > docs/_build/unix-socket.json
	@./docs/_build/parse.native lib/_build/unix-direct > docs/_build/unix-direct.json
	@./docs/_build/parse.native lib/_build/node > docs/_build/node.json
#	@./docs/_build/parse.native lib/_build/xen > docs/_build/xen.json


install:
	@rm -rf _build
	@./assemble.sh
	@mkdir -p $(PREFIX)
	@cp -r _build/* $(PREFIX)/

clean:
	@cd syntax && $(MAKE) clean
	@cd lib && $(MAKE) clean
	@cd tools && $(MAKE) clean
	@cd regress && $(MAKE) clean
	@cd docs && $(MAKE) clean
	@rm -rf _build

install-el:
	@cd scripts/caml-mode && $(MAKE) install-el

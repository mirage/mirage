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

all: tools
	@cd syntax && $(MAKE)
	@cd lib && $(MAKE)

doc:
	@cd lib && $(MAKE) doc

tools:
	@cd tools/crunch && ocamlbuild $(JOBS) crunch.native
	@cd tools/mir && $(MAKE) install
	@cp tools/crunch/_build/crunch.native $(PREFIX)/bin/mlcrunch
	@$(MAKE) -C tools/fs all
	@cp tools/fs/mir-fs-create $(PREFIX)/bin/mir-fs-create

install:
	@rm -rf _build
	@./assemble.sh
	@mkdir -p $(PREFIX)
	@cp -r _build/* $(PREFIX)/

clean:
	@cd syntax && $(MAKE) clean
	@cd lib && $(MAKE) clean
	@cd tools/crunch && ocamlbuild -clean

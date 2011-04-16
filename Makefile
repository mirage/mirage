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

tools:
	@cd tools/mpl && ocamlbuild $(JOBS) mplc.native
	@cd tools/crunch && ocamlbuild $(JOBS) crunch.native
	@cd tools/mir && $(MAKE) install
	@cp tools/mpl/_build/mplc.native $(PREFIX)/bin/mplc
	@cp tools/crunch/_build/crunch.native $(PREFIX)/bin/mlcrunch

install:
	@rm -rf _build
	@./assemble.sh
	@mkdir -p $(PREFIX)
	@cp -r _build/* $(PREFIX)/

clean:
	@cd syntax && $(MAKE) clean
	@cd lib && $(MAKE) clean
	@cd tools/mpl && ocamlbuild -clean
	@cd tools/crunch && ocamlbuild -clean

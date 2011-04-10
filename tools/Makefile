PREFIX ?= $(HOME)/mir-inst
export PREFIX

JOBS ?= -j 4

all:
	@cd mpl && ocamlbuild $(JOBS) mplc.native
	@cd crunch && ocamlbuild $(JOBS) crunch.native
	@cd mir && $(MAKE) install
	@cp mpl/_build/mplc.native $(PREFIX)/bin/mplc
	@cp crunch/_build/crunch.native $(PREFIX)/bin/mlcrunch

.PHONY: clean
clean:
	@cd mpl && ocamlbuild -clean
	@cd crunch && ocamlbuild -clean

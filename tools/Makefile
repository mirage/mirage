.PHONY: all
all:
	@cd mpl && $(MAKE)
	@cd ocamldsort && if [ ! -f Makefile ]; then ./configure; fi
	@cd ocamldsort && $(MAKE)

.PHONY: clean
clean:
	@cd mpl && $(MAKE) clean
	@cd ocamldsort && $(MAKE) clean || true

.PHONY: install
install:
	cd mpl && $(MAKE) install
	cd ocamldsort && $(MAKE) install

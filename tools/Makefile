.PHONY: all
all:
	cd mpl && $(MAKE)
	cd ocamldsort && ./configure && $(MAKE)

.PHONY: clean
clean:
	cd mpl && $(MAKE) clean
	cd ocamldsort && $(MAKE) clean

.PHONY: install
install:
	cd mpl && $(MAKE) install
	cd ocamldsort && $(MAKE) install

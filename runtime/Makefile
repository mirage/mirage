.PHONY: all clean install

OCAML_PREFIX=$(shell ocamlopt -where)

all:
	@cd base && $(MAKE)

clean:
	@cd base && $(MAKE) clean

install:
	cp libmiragerun.a $(DESTDIR)$(OCAML_PREFIX)/mirage/

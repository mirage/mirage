.PHONY: all clean
-include Makefile.config

JOBS ?= -j 5

all:
	@ocamlbuild $(JOBS) $(OFLAGS) all.otarget -no-links

clean:
	@ocamlbuild -clean

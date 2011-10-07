.PHONY: all clean

JOBS ?= -j 5

all:
	@ocamlbuild $(JOBS) all.otarget -no-links

clean:
	@ocamlbuild -clean

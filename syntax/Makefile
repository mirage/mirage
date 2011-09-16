.PHONY: all clean

JOBS ?= -j 5

all:
	@ocamlbuild $(JOBS) -classic-display -use-ocamlfind all.otarget

clean:
	@ocamlbuild -clean

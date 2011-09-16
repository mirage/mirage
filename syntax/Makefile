.PHONY: all clean

JOBS ?= -j 5

all:
	@ocamlbuild $(JOBS) -classic-display -use-ocamlfind allopt.otarget all.otarget

clean:
	@ocamlbuild -clean

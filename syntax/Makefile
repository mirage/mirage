.PHONY: all clean

JOBS ?= -j 4

all:
	ocamlbuild $(JOBS) -use-ocamlfind all.otarget

clean:
	ocamlbuild -clean

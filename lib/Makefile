.PHONY: all unix clean

JOBS ?= -j 4

all: unix

unix:
	ocamlbuild $(JOBS) unix.otarget

xen:
	ocamlbuild $(JOBS) xen.otarget

clean:
	ocamlbuild -clean

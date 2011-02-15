.PHONY: all unix clean
all: unix
	@ :

unix:
	env MIRAGEOS=unix ocamlbuild -classic-display net.cmxa

clean:
	ocamlbuild -clean

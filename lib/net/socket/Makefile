.PHONY: all unix clean
all: unix node
	@ :

unix:
	env MIRAGEOS=unix ocamlbuild $(JOBS) net.cmxa

node:
	env MIRAGEOS=node ocamlbuild $(JOBS) net.cma

clean:
	ocamlbuild -clean

.PHONY: all unix clean
all: unix
	@ :

unix:
	env MIRAGEOS=unix ocamlbuild $(JOBS) net.cmxa

clean:
	ocamlbuild -clean

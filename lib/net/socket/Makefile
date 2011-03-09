NODE = $(shell ocamlfind query js_of_ocaml 2>/dev/null)

ifeq ($(NODE),)
NODE_BUILD=
else
NODE_BUILD=node
endif

.PHONY: all unix clean
all: unix $(NODE_BUILD)
	@ :

unix:
	env MIRAGEOS=unix ocamlbuild $(JOBS) net.cmxa

node:
	env MIRAGEOS=node ocamlbuild $(JOBS) net.cma

clean:
	ocamlbuild -clean

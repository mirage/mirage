all: static.ml
	ocamlbuild lib/debugger.cmx

static.ml:
	mlcrunch static/ > lib/static.ml

clean:
	ocamlbuild -clean
	rm -f lib/static.ml
.PHONY: all clean

all: _build/odoc_json.cmo _build/odoc_json.cmxs
	@ :

_build/odoc_json.cmo _build/odoc_json.cmxs: odoc_json.ml
	ocamlbuild -cflag -I -cflag +ocamldoc odoc_json.cmo odoc_json.cmxs

clean:
	ocamlbuild -clean

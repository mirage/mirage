all:
	ocaml pkg/pkg.ml build

test:
	ocaml pkg/pkg.ml test

clean:
	rm -rf _build

all:
	ocaml pkg/pkg.ml build --pkg-name mirage-types
	ocaml pkg/pkg.ml build --pkg-name mirage

clean:
	rm -rf _build

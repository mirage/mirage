all:
	ocaml pkg/pkg.ml build --pkg-name mirage-types
	ocaml pkg/pkg.ml build --pkg-name mirage

clean:
	ocaml pkg/pkg.ml clean --pkg-name mirage-types
	ocaml pkg/pkg.ml clean --pkg-name mirage

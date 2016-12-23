all:
	ocaml pkg/pkg.ml build --pkg-name mirage-types -q
	ocaml pkg/pkg.ml build --pkg-name mirage-types-lwt -q
	ocaml pkg/pkg.ml build --pkg-name mirage-runtime -q
	ocaml pkg/pkg.ml build --pkg-name mirage -q

clean:
	ocaml pkg/pkg.ml clean

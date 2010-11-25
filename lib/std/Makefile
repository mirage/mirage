unix xen:
	cp sig/*.mli lib/
	ocamlbuild -use-ocamlfind syntax/pa_lwt.cmo
	ocamlbuild lib/stdlib.cmxa
	ocamlbuild -pp "camlp4o syntax/pa_build.cmo" lib/lwt.mllib

clean:
	rm lib/*.mli
	ocamlbuild -clean

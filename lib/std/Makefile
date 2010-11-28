unix xen:
	cp sig/*.mli lib/
	ocamlbuild -use-ocamlfind syntax/pa_lwt.cmo
	ocamlbuild lib/stdlib.cmxa
	ocamlbuild lib/lwt.cmxa

clean:
	rm -f lib/*.mli
	ocamlbuild -clean

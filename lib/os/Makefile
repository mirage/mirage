unix:
	cp sig/*.mli lib_unix/
	ocamlbuild lib_unix/oS.cmxa

xen:
	cp sig/*.mli lib_xen/
	ocamlbuild lib_xen/oS.cmxa

clean:
	rm -f lib_unix/*.mli
	cd lib_xen && rm -f hw_page.mli main.mli time.mli
	ocamlbuild -clean
.PHONY: init
init: .init
	@

.init:
	touch .init
	cp -r ../tools/ocaml-libs/dyntype/lib misc/dyntype
	cp -r ../tools/ocaml-libs/htcaml/lib misc/html
	cp -r ../tools/ocaml-libs/xmlm/src misc/xml
	cd misc && patch -p1 < xmlm1.diff
	cd misc && patch -p1 < xmlm2.diff
	cd misc && patch -p1 < dyntype1.diff

clean:
	rm -rf .init
	rm -rf misc/dyntype
	rm -rf misc/html
	rm -rf misc/xml

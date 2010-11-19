PREFIX ?= ~/mir-inst
MIRAGE_ROOT ?= $(PREFIX)/lib/ocaml/mirage

all: .init pa_mirage.mllib
	ocamlbuild pa_mirage.cma

.init: 
	cp -r ../tools/ocaml-libs/dyntype/pa_lib dyntype
	cp -r ../tools/ocaml-libs/dyntype/lib dyntype-lib
	cp -r ../tools/ocaml-libs/htcaml/pa_lib html
	cp -r ../tools/ocaml-libs/xmlm/src xml
	touch .init

pa_mirage.mllib: .init
	cat ../tools/ocaml-libs/dyntype/pa_lib/pa_dyntype.mllib > pa_mirage.mllib
	echo "\n" >> pa_mirage.mllib
	cat ../tools/ocaml-libs/dyntype/lib/dyntype.mllib >> pa_mirage.mllib
	echo "\n" >> pa_mirage.mllib
	cat ../tools/ocaml-libs/htcaml/pa_lib/pa_htcaml.mllib >> pa_mirage.mllib
	echo Xmlm >> pa_mirage.mllib
	echo Pa_lwt >> pa_mirage.mllib
	echo Pa_type_conv >> pa_mirage.mllib

clean:
	rm .init
	rm -rf dyntype dyntype-lib
	rm -rf html
	rm -rf xml
	rm -f pa_mirage.mllib
	ocamlbuild -clean

install:
	mkdir -p $(MIRAGE_ROOT)/syntax
	cp _build/pa_mirage.cma $(MIRAGE_ROOT)/syntax/pa_mirage.cma

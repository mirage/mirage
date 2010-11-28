PREFIX ?= ~/mir-inst
MIRAGE_ROOT ?= $(PREFIX)/lib/ocaml/mirage

all: pa_mirage.mllib
	ocamlbuild pa_mirage.cma

pa_mirage.mllib:
	cat dyntype/pa_dyntype.mllib > pa_mirage.mllib
	echo "\n" >> pa_mirage.mllib
	cat dyntype-lib/dyntype.mllib >> pa_mirage.mllib
	echo "\n" >> pa_mirage.mllib
	cat html/pa_htcaml.mllib >> pa_mirage.mllib
	echo Xmlm >> pa_mirage.mllib
	echo Pa_lwt >> pa_mirage.mllib
	echo Pa_type_conv >> pa_mirage.mllib

clean:
	rm -f pa_mirage.mllib
	ocamlbuild -clean

install:
	mkdir -p $(MIRAGE_ROOT)/syntax
	cp _build/pa_mirage.cma $(MIRAGE_ROOT)/syntax/pa_mirage.cma

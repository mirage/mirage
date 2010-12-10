.PHONY: all clean

all: clean
	mir json/main.bin
	mir twitter/main.bin
	_build/json/main.bin && _build/twitter/main.bin

clean:
	rm -f myocamlbuild.ml
	ocamlbuild -clean
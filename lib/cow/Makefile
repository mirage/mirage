.PHONY: all lib syntax clean

all: syntax lib
	@ :

syntax: syntax/html/xml.ml
	ocamlbuild syntax.otarget

syntax/html/xml.ml:
	@cd syntax/html && ln -nsf ../../lib/xml.ml .

lib: syntax
	ocamlbuild lib.otarget

clean:
	rm -f syntax/html/xml.ml
	ocamlbuild -clean

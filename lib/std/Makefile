.PHONY: all clean

PA_LWT=_build/syntax/pa_lwt.cmo
STDLIB=_build/lib/stdlib.cmxa
LWT=_build/lib/lwt.cmxa

all: $(STDLIB) $(LWT)
	@ :

$(PA_LWT):
	ocamlbuild -use-ocamlfind syntax/pa_lwt.cmo

$(STDLIB):
	ocamlbuild lib/stdlib.cmxa

$(LWT): $(PA_LWT) $(STDLIB)
	ocamlbuild lib/lwt.cmxa

clean:
	ocamlbuild -clean


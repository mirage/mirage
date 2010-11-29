.PHONY: clean all

LIBUNIX=_build/lib_unix/oS.cmxa
LIBXEN=_build/lib_xen/oS.cmxa

.PHONY: all
all: $(LIBUNIX) $(LIBXEN)
	@ :

_build/%:
	ocamlbuild $*

clean:
	ocamlbuild -clean

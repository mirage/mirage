ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

.PHONY: build
build: stdlib.cmxa
	@ :

.mldeps: *.ml *.mli
	$(OCAMLDSORT) -mli *.ml *.mli > $@

.cmxdeps: .mldeps
	$(OCAMLDSORT) -opt *.ml > $@

stdlib.cmxa: .cmxdeps .mldeps
	$(OCAMLOPT) -c -nostdlib -nopervasives $(OCAMLOPT_FLAGS) \
	  pervasives.mli pervasives.ml `cat .mldeps`
	$(OCAMLOPT) -a -o stdlib.cmxa `cat .cmxdeps`

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps

ROOTDIR=..
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

pervasives.cmi: pervasives.mli
	$(OCAMLOPT) -c -nostdlib -nopervasives $(OCAMLOPT_FLAGS) $<

pervasives.cmx: pervasives.ml pervasives.cmi
	$(OCAMLOPT) -c -nostdlib -nopervasives $(OCAMLOPT_FLAGS) $<

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps

OCAML_PREFIX = $(shell $(OCAMLOPT) -where)

.PHONY: install
install:
	mkdir -p $(DESTDIR)$(OCAML_PREFIX)/mirage
	cp *.cmi *.cmxa *.cmx *.a $(DESTDIR)$(OCAML_PREFIX)/mirage/

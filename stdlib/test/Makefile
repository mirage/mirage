OCAMLOPT ?= ocamlopt.opt
OCAMLDSORT ?= ocamldsort.opt
RESULT = foo
STDLIB = ../src
OCAMLDIR = $(shell ocamlc -where)
ASMLIB ?= $(OCAMLDIR)/libasmrun.a


.PHONY: build
$(RESULT): pervasives.ml
	$(OCAMLOPT) -c -nopervasives -nostdlib pervasives.mli pervasives.ml
	$(OCAMLOPT) -c -nopervasives -nostdlib $(shell $(OCAMLDSORT) -mli *.mli)
	$(OCAMLOPT) -linkall -nopervasives -nostdlib -o $(RESULT) $(shell $(OCAMLDSORT) *.ml) $(ASMLIB)

pervasives.ml:
	@for i in $(wildcard $(STDLIB)/*.ml $(STDLIB)/*.mli); do ln -nfs $$i; done

.PHONY: clean
clean:
	rm -f *.cmx *.cmi *.a *.o *.cmo $(RESULT)
	find . -type l -exec rm -f {} \;

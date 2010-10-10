ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

SRC=value.mli type.mli string.mli str.mli stack.mli sort.mli set.mli queue.mli printexc.mli nativeint.mli marshal.mli map.mli list.mli lexing.mli int64.mli int32.mli hashtbl.mli gc.mli digest.mli complex.mli char.mli camlinternalLazy.mli callback.mli buffer.mli array.mli std_exit.ml weak.mli sys.mli scanf.mli random.mli obj.mli string.ml str.ml stack.ml sort.ml set.ml marshal.ml map.ml list.ml int64.ml int32.ml complex.ml char.ml array.ml printf.mli parsing.mli camlinternalOO.mli camlinternalMod.mli weak.ml sys.ml random.ml queue.ml obj.ml nativeint.ml lexing.ml hashtbl.ml camlinternalLazy.ml callback.ml buffer.ml oo.mli value.ml type.ml scanf.ml printf.ml printexc.ml parsing.ml gc.ml digest.ml camlinternalOO.ml camlinternalMod.ml oo.ml format.mli format.ml
CMJS=std_exit.cmjs sys.cmjs set.cmjs map.cmjs list.cmjs int64.cmjs int32.cmjs complex.cmjs char.cmjs array.cmjs string.cmjs stack.cmjs sort.cmjs nativeint.cmjs hashtbl.cmjs marshal.cmjs lexing.cmjs buffer.cmjs str.cmjs obj.cmjs weak.cmjs queue.cmjs printf.cmjs parsing.cmjs camlinternalOO.cmjs camlinternalLazy.cmjs callback.cmjs value.cmjs type.cmjs scanf.cmjs printexc.cmjs oo.cmjs gc.cmjs digest.cmjs camlinternalMod.cmjs random.cmjs format.cmjs

.PHONY: build
build: stdlib.cmjsa
	@ :

OCAMLDIR=$(shell ocamljs -where)/site-lib
PP=-pp "camlp4o -I $(OCAMLDIR)/ulex -I $(OCAMLDIR)/jslib ulexing.cma jslib.cma syntax_inline.cmo"

ocamljs.cmjs ocamljs.cmi: ocamljs.mli ocamljs.ml
	$(OCAMLJS) -c -nostdlib -nopervasives $^

pervasives.cmjs pervasives.cmi: pervasives.mli pervasives.ml ocamljs.cmi
	$(OCAMLJS) -c -nostdlib -nopervasives pervasives.mli pervasives.ml

$(CMJS): pervasives.cmi ocamljs.cmi
	$(OCAMLJS) -c -nostdlib -nopervasives $(PP) $(SRC)

stdlib.cmjsa: ocamljs.cmjs pervasives.cmjs $(CMJS)
	$(OCAMLJS) -a -o $@ $^	

.PHONY: clean
clean:
	rm -f *.cmx *.cmo *.o *.cmi *.cmxa .mldeps .cmxdeps *.cmjs *.cmjsa *.annot


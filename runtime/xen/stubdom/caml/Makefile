XEN_ROOT = ../..

include $(XEN_ROOT)/Config.mk

CAMLLIB = $(shell ocamlc -where)
DEF_CPPFLAGS += -I(CAMLLIB)

OCAMLOPT=$(OCAMLC_CROSS_PREFIX)ocamlopt

OBJS := hello.cmx
LIBS := 

all: main-caml.o caml.o

%.cmx: %.ml
	$(OCAMLOPT) -c $< -o $@

caml.o: $(OBJS)
	$(OCAMLOPT) $(LIBS) $^ -output-obj -o $@

clean:
	rm -f *.a *.o *.cmx *.cmi

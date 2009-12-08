XEN_ROOT = ../..

include $(XEN_ROOT)/Config.mk

CAMLLIB = $(shell ocamlc -where)
DEF_CPPFLAGS += -I$(CAMLLIB)

all: main-caml.o

clean:
	rm -f *.a *.o *.cmx *.cmi

# before including this, define ROOTDIR to the repository root

CC ?= gcc
CFLAGS += -O2
CFLAGS += -I"$(shell $(OCAMLC) -where)/caml"


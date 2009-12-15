# define ROOTDIR before using this makefile fragment
include $(ROOTDIR)/mk/base.mk

OCAMLC ?= ocamlc.opt
OCAMLOPT ?= ocamlopt.opt
OCAMLDSORT ?= ocamldsort

ifeq ($(OS),macosx)
OCAMLOPT_FLAGS =
else
OCAMLOPT_FLAGS = -fno-PIC -nodynlink
endif

OCAMLDEP ?= ocamldep.opt

OCAMLOPT_BUILD = env CAMLLIB=$(ROOTDIR)/stdlib $(OCAMLOPT) 

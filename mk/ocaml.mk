# define ROOTDIR before using this makefile fragment
OS = $(shell uname -s)

OCAMLC ?= ocamlc.opt
OCAMLOPT ?= ocamlopt.opt
OCAMLDSORT ?= ocamldsort

ifeq ($(OS),Darwin)
OCAMLOPT_FLAGS =
else
OCAMLOPT_FLAGS = -fno-PIC -nodynlink
endif

OCAMLDEP ?= ocamldep.opt

OCAMLOPT_BUILD = env CAMLLIB=$(ROOTDIR)/stdlib $(OCAMLOPT) 

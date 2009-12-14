# define ROOTDIR before using this makefile fragment

OCAMLC ?= ocamlc.opt
OCAMLOPT ?= ocamlopt.opt
OCAMLDSORT ?= ocamldsort

OCAMLOPT_FLAGS = -fno-PIC -nodynlink

OCAMLOPT_BUILD = env CAMLLIB=$(ROOTDIR)/stdlib $(OCAMLOPT) 

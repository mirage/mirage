# define ROOTDIR before using this makefile fragment

OCAMLC ?= ocamlc.opt
OCAMLOPT ?= ocamlopt.opt
OCAMLDSORT ?= ocamldsort
OCAMLOPT_FLAGS = -fno-PIC -nodynlink
OCAMLDEP ?= ocamldep.opt

OCAMLOPT_BUILD = env CAMLLIB=$(ROOTDIR)/stdlib $(OCAMLOPT) 

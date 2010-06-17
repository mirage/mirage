#!/bin/sh
#########################################################################
#                                                                       #
#                            Objective Caml                             #
#                                                                       #
#            Damien Doligez, projet Para, INRIA Rocquencourt            #
#                                                                       #
#   Copyright 1999 Institut National de Recherche en Informatique et    #
#   en Automatique.  All rights reserved.  This file is distributed     #
#   under the terms of the Q Public License version 1.0.                #
#                                                                       #
#########################################################################

# $Id: ocamlmktop.tpl 6128 2004-02-22 14:52:50Z xleroy $

exec %%BINDIR%%/ocamlc -linkall toplevellib.cma "$@" topstart.cmo

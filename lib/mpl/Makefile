ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

TARGET=mpl
TARGET_MLI=
MPL=ethernet ipv4 udp icmp dhcp dns_rr dns tcp
SOURCES=mpl_stdlib.mli mpl_stdlib.ml $(MPL:%=%.ml)
DEPENDS=lwt

WITH_SYNTAX=yes
EXTRA_FLAGS=-w y
EXTRA_CLEAN=mpl.ml

USE_PACK=yes
include ../Makefile.common

.PHONY: depend
depend: $(MPLDEPS)
	@ :

%.ml: %.mpl
	mplc -v $< > $@


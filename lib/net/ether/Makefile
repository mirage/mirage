ROOTDIR=../../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=lwt net/mpl os/xen
SOURCES=types.mli types.ml checksum.ml ethif.ml arp.mli arp.ml ipv4.mli ipv4.ml udp.mli udp.ml tcp.mli tcp.ml 

TARGET=mlnet
TARGET_MLI=mlnet.mli

EXTRA_CLEAN=mlnet.ml
WITH_SYNTAX=yes
USE_PACK=yes
include ../../Makefile.common

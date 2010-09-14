ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=stdlib lwt mpl
SOURCES=types.mli types.ml time.mli ethernet.mli ethif.mli arp.mli ipv4.mli udp.mli tcp.mli

TARGET=mlnet
TARGET_MLI=

EXTRA_CLEAN=mlnet.ml
WITH_SYNTAX=yes
USE_PACK=yes
include ../Makefile.common

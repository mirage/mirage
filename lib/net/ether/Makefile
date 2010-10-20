ROOTDIR=../../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=lwt net/api net/mpl os/unix
SOURCES=checksum.ml ethif.ml arp.mli arp.ml ipv4.mli ipv4.ml icmp.ml udp.mli udp.ml tcp.mli tcp.ml 

TARGET=mlnet

EXTRA_CLEAN=mlnet.ml
WITH_SYNTAX=yes
USE_PACK=yes
include ../../Makefile.common

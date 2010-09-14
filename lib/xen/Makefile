ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=lwt mpl
TARGET=xen
TARGET_MLI=xen.mli
SOURCES=hw_page.mli hw_page.ml gnttab.mli gnttab.ml ring.ml evtchn.ml activations.ml \
	xb_op.ml xb_partial.ml xb_state.ml \
	xs_packet.ml xb.mli xb.ml queueop.ml xsraw.mli xsraw.ml \
	xst.mli xst.ml clock.ml main.ml time.ml xs.mli xs.ml ethif.ml console.ml 

WITH_SYNTAX=yes
NO_JS_CODE=yes
USE_PACK=yes
include ../Makefile.common

ROOTDIR=../..
include $(ROOTDIR)/mk/ocaml.mk

# XXX: fix PCRE path
EXTRA_FLAGS+=-I ../../tools/ocaml-libs/pcre-ocaml-release-6.1.0/lib
DEPENDS=lwt mpl unix io mlnet
FILES = http_types http_constants http_misc base64 http_url http_common http_parser_sanity \
				http_parser http_user_agent http_message http_response http_request http_cookie 
SOURCES=$(foreach file,$(FILES), $(file).mli $(file).ml)

TARGET=cohttp
TARGET_MLI=

EXTRA_CLEAN=cohttp.ml
WITH_SYNTAX=yes
USE_PACK=yes
include ../Makefile.common

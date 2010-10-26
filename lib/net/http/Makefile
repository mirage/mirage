ROOTDIR=../../../
include $(ROOTDIR)/mk/ocaml.mk

DEPENDS=os/unix net/api net/socket/unix
FILES = http_types http_constants http_misc base64 http_url http_common http_parser_sanity \
	http_parser http_user_agent http_message http_response http_request http_cookie \
 	http_daemon
SOURCES=$(foreach file,$(FILES), $(file).mli $(file).ml)

TARGET=http

WITH_SYNTAX=yes
USE_PACK=yes
include ../../Makefile.common

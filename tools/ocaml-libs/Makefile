ROOTDIR=../..
include $(ROOTDIR)/mk/base.mk

ifeq ($(OS),macosx)
FETCH=ftp -v
else
FETCH=wget
endif

PREFIX ?= /usr/local

.PHONY: all
all: findlib ulex xmlm
	@ :

.PHONY: findlib
FINDLIB_VERSION=1.2.6
findlib:
	[ ! -s "findlib-$(FINDLIB_VERSION).tar.gz" ] && $(FETCH) http://download.camlcity.org/download/findlib-$(FINDLIB_VERSION).tar.gz
	rm -rf findlib-$(FINDLIB_VERSION)
	tar -zxf findlib-$(FINDLIB_VERSION).tar.gz
	cd findlib-$(FINDLIB_VERSION) && ./configure -bindir $(PREFIX)/bin -mandir $(PREFIX)/man -sitelib $(PREFIX)/lib/ocaml/site-lib -config $(PREFIX)/etc/ocamlfind.conf && $(MAKE) && $(MAKE) install

.PHONY: ulex
ULEX_VERSION=1.1
ulex: findlib
	[ ! -s "ulex-$(ULEX_VERSION).tar.gz" ] && $(FETCH) http://www.cduce.org/download/ulex-$(ULEX_VERSION).tar.gz
	rm -rf ulex-$(ULEX_VERSION)
	tar -zxf ulex-$(ULEX_VERSION).tar.gz
	cd ulex-$(ULEX_VERSION) && $(MAKE) && $(MAKE) install

.PHONY: xmlm
XMLM_VERSION=1.0.2-patched
xmlm: findlib
	[ ! -s "xmlm-$(XMLM_VERSION).tar.gz" ] && $(FETCH) http://gazagnaire.org/projects/xmlm-$(XMLM_VERSION).tar.gz
	rm -rf xmlm-$(XMLM_VERESION)
	tar xvfz xmlm-$(XMLM_VERSION).tar.gz
	cd xmlm-$(XMLM_VERSION) && $(MAKE) && $(MAKE) install

.PHONY: clean
clean:
	rm -rf ulex* findlib* xmlm*

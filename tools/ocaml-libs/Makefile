ROOTDIR=../..
include $(ROOTDIR)/mk/base.mk

ifeq ($(OS),macosx)
FETCH=ftp
else
FETCH=wget
endif

PREFIX ?= /usr/local

.PHONY: all
all: findlib ulex
	@ :

.PHONY: findlib
FINDLIB_VERSION=1.2.6
findlib:
	$(FETCH) http://download.camlcity.org/download/findlib-$(FINDLIB_VERSION).tar.gz
	rm -rf findlib-$(FINDLIB_VERSION)
	tar -zxf findlib-$(FINDLIB_VERSION).tar.gz
	cd findlib-$(FINDLIB_VERSION) && ./configure -bindir $(PREFIX)/bin -mandir $(PREFIX)/man -sitelib $(PREFIX)/lib/ocaml/site-lib -config $(PREFIX)/etc/ocamlfind.conf && $(MAKE) && $(MAKE) install

.PHONY: ulex
ULEX_VERSION=1.1
ulex: findlib
	$(FETCH) http://www.cduce.org/download/ulex-$(ULEX_VERSION).tar.gz
	rm -rf ulex-$(ULEX_VERSION)
	tar -zxf ulex-$(ULEX_VERSION).tar.gz
	cd ulex-$(ULEX_VERSION) && $(MAKE) && $(MAKE) install

.PHONY: clean
clean:
	rm -rf ulex* findlib*

uninstall:
	@cd ulex-$(ULEX_VERSION) && $(MAKE) uninstall
	@cd findlib-$(FINDLIB_VERSION) && $(MAKE) uninstall

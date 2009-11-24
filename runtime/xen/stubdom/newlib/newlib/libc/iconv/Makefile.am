## Process this file with automake to generate Makefile.in
AUTOMAKE_OPTIONS = cygnus

SUBDIRS = ces ccs lib .

cctdir=$(datadir)/iconv_data
cct_DATA=encoding.aliases

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

SUBDEFS = lib/stmp-def

include $(srcdir)/../../Makefile.shared

CHEWOUT_FILES = iconv.def

iconv.def: lib/iconv.def
	cp lib/iconv.def iconv.def

stmp-def: force
	(cd lib && make doc)
	touch $@

.PHONY: force
force:

$(SUBDEFS): stmp-def

lib/iconv.def: $(SUBDEFS); @true

lib/stmp-def: ; @true

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/iconv.tex >> $(TARGETDOC)

CLEANFILES = $(CHEWOUT_FILES) *.ref


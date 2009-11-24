## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = \
	utf-8.c \
	utf-16.c \
	ucs-2.c \
	us-ascii.c \
	ucs-4.c \
	ucs-2-internal.c \
	ucs-4-internal.c \
	cesbi.c \
	table.c \
	table-pcs.c \
	euc.c

## The following interfaces are EL/IX level 2
if ELIX_LEVEL_1
ELIX_SOURCES = \
	utf-8.c \
	utf-16.c \
	ucs-2.c \
	us-ascii.c \
	ucs-4.c \
	ucs-2-internal.c \
	ucs-4-internal.c \
	cesbi.c \
	table.c \
	table-pcs.c \
	euc.c
else
ELIX_SOURCES = 
endif

noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =

include $(srcdir)/../../../Makefile.shared

CHEWOUT_FILES = ces.def

SUFFIXES = .def

CHEW = ../../../doc/makedoc -f $(srcdir)/../../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/ces.tex >> $(TARGETDOC)

CLEANFILES = $(CHEWOUT_FILES) *.ref


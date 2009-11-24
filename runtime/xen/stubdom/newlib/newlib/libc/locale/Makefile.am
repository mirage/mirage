## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = timelocal.h ldpart.h locale.c lnumeric.h lmonetary.h lmessages.h 

## The following interfaces are EL/IX level 2
if ELIX_LEVEL_1
ELIX_SOURCES =
else
ELIX_SOURCES = \
	fix_grouping.c \
	ldpart.c \
	lmessages.c \
	lnumeric.c \
	lmonetary.c \
	nl_langinfo.c \
	timelocal.c
endif

liblocale_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = liblocale.la
liblocale_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared

CHEWOUT_FILES = locale.def

SUFFIXES = .def

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/locale.tex >> $(TARGETDOC)

CLEANFILES = $(CHEWOUT_FILES) *.ref


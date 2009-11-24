## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = \
	fnmatch.c glob.c regcomp.c regerror.c regex2.h \
	regexec.c regfree.c collate.h collate.c collcmp.c \
	reallocf.c

ELIX_3_SOURCES = \
	wordexp.c \
	wordfree.c

if ELIX_LEVEL_1
ELIX_SOURCES =
else
if ELIX_LEVEL_2
ELIX_SOURCES =
else
ELIX_SOURCES = $(ELIX_3_SOURCES)
endif
endif

libstdlib_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libstdlib.la
libstdlib_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

AM_CFLAGS = -D_GNU_SOURCE

include $(srcdir)/../../../../Makefile.shared

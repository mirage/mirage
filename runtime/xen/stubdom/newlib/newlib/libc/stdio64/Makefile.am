## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

# need a dummy object so objectlist.awk.in will build every time
GENERAL_SOURCES = dummy.c local64.h

## All interfaces are EL/IX level 2
if ELIX_LEVEL_1
ELIX_SOURCES =
else
ELIX_SOURCES = \
	fdopen64.c 	\
	fgetpos64.c	\
	fopen64.c 	\
	freopen64.c 	\
	fseeko64.c 	\
	fsetpos64.c 	\
	ftello64.c	\
	stdio64.c	\
	tmpfile64.c
endif

libstdio64_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libstdio64.la
libstdio64_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
LIB_COMPILE = $(LTCOMPILE)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
LIB_COMPILE = $(COMPILE)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared

AM_CFLAGS = -I $(srcdir)/../stdio

CHEWOUT_FILES = \
	fgetpos64.def		\
	fopen64.def		\
	freopen64.def		\
	fseeko64.def		\
	fsetpos64.def		\
	ftello64.def		\
	tmpfile64.def

SUFFIXES = .def

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/stdio64.tex >> $(TARGETDOC)

CLEANFILES = $(CHEWOUT_FILES) *.ref


## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

## All functions in this directory are EL/IX level 2 and above
if ELIX_LEVEL_1
ELIX_SOURCES =
else
ELIX_SOURCES = 		\
	argz_add.c 	\
	argz_add_sep.c 	\
	argz_append.c 	\
	argz_count.c 	\
	argz_create.c 	\
	argz_create_sep.c \
	argz_delete.c 	\
	argz_extract.c 	\
	argz_insert.c 	\
	argz_next.c 	\
	argz_replace.c 	\
	argz_stringify.c \
	buf_findstr.c 	\
	envz_entry.c 	\
	envz_get.c 	\
	envz_add.c 	\
	envz_remove.c 	\
	envz_merge.c 	\
	envz_strip.c
endif

libargz_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libargz.la
libargz_la_SOURCES = dummy.c $(ELIX_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = dummy.c $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

SUFFIXES = .def

CHEWOUT_FILES =

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)

CLEANFILES = $(CHEWOUT_FILES) *.ref

include $(srcdir)/../../Makefile.shared

## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -DGCONV_DIR='"$(pkglibdir)"' -DGCONV_PATH='"$(pkglibdir)"' -I$(srcdir) -I$(srcdir)/.. $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

LIB_SOURCES = \
	iconv.h gconv.h \
	iconv_open.c iconv.c iconv_close.c \
	gconv_open.c gconv.c gconv_close.c \
	gconv_db.c gconv_dl.c gconv_conf.c gconv_builtin.c \
	gconv_simple.c gconv_trans.c gconv_cache.c

libiconv_la_CFLAGS =
libiconv_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libiconv.la
libiconv_la_SOURCES = $(LIB_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(LIB_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../../../Makefile.shared

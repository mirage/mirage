## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -DSHARED -D_GNU_SOURCE $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS) -I$(srcdir)/..

LIB_SOURCES = \
	dl-addr.c   dl-deps.c   dl-init.c         dl-load.c     dl-misc.c    dl-profile.c   dl-runtime.c  dl-version.c \
	dl-close.c  dl-error.c  dl-iteratephdr.c  dl-lookup.c   dl-object.c  dl-profstub.c  dl-support.c \
	dl-debug.c  dl-fini.c   dl-libc.c         dl-open.c    dl-reloc.c     dl-sym.c   dl-cache.c

AM_CFLAGS = -D_GNU_SOURCE -D__strerror_r=strerror_r
libdl_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libdl.la
libdl_la_SOURCES = $(LIB_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(LIB_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../../../Makefile.shared

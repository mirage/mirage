## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I$(srcdir)/../../../include -I$(srcdir)/../.. -I$(srcdir)/../generic -I$(srcdir)/../../.. $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = -I. -I$(srcdir) $(INCLUDES)

LIB_SOURCES = clone.S i386-sysdep.S pspinlock.c sysdep.S

liblinuxthreadsi386_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = liblinuxthreadsi386.la
liblinuxthreadsi386_la_SOURCES = $(LIB_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(LIB_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../../../../../Makefile.shared

AM_CFLAGS = -D_XOPEN_SOURCE=600 -D_GNU_SOURCE=1

ACLOCAL_AMFLAGS = -I ../../../../../.. -I ../../../../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

# We also make a library with just the useful
# machine-but-not-system-specific functions, usable as an add-on
# by itself together with e.g. uclibc.
toollib_LIBRARIES = libic.a

lib_a_SOURCES = setjmp.c memcpy.c memset.c memmove.c libcdtor.c
lib_a_CCASFLAGS=$(AM_CCASFLAGS)
lib_a_CFLAGS=$(AM_CFLAGS)

libic_a_SOURCES = setjmp.c memcpy.c memset.c memmove.c libcdtor.c
libic_a_CCASFLAGS=$(AM_CCASFLAGS)
libic_a_CFLAGS=$(AM_CFLAGS)
tooldir = $(exec_prefix)/$(host_alias)
toollibdir = $(tooldir)/lib$(MULTISUBDIR)

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

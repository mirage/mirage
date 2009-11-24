## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

AM_CFLAGS = -I $(srcdir)/../../stdio -I $(srcdir)/../../stdlib

lib_a_SOURCES = setjmp.S times.c
lib_a_CCASFLAGS=$(AM_CCASFLAGS)
lib_a_CFLAGS=$(AM_CFLAGS)
lib_a_LIBADD = @extra_objs@
lib_a_DEPENDENCIES = @extra_objs@

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../.. 
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

VEC_MALLOC_COMPILE = $(COMPILE) -DINTERNAL_NEWLIB

$(lpfx)vec_reallocr.o: vec_mallocr.c
	$(VEC_MALLOC_COMPILE) -DDEFINE_VECREALLOC -c $(srcdir)/vec_mallocr.c -o $@

$(lpfx)vec_callocr.o: vec_mallocr.c
	$(VEC_MALLOC_COMPILE) -DDEFINE_VECCALLOC -c $(srcdir)/vec_mallocr.c -o $@


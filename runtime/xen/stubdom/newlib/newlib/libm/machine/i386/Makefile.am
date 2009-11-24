## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I $(newlib_basedir)/../newlib/libm/common $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

LIB_SOURCES = \
	f_atan2.S f_atan2f.S f_exp.c f_expf.c \
	f_frexp.S f_frexpf.S f_llrint.c f_llrintf.c f_llrintl.c \
	f_log.S f_logf.S f_log10.S f_log10f.S \
	f_ldexp.S f_ldexpf.S f_lrint.c f_lrintf.c f_lrintl.c \
	f_pow.c f_powf.c f_rint.c f_rintf.c f_rintl.c \
	f_tan.S f_tanf.S f_math.h \
	i386mach.h 

libi386_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libi386.la
libi386_la_SOURCES = $(LIB_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(LIB_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
noinst_DATA = 
endif # USE_LIBTOOL

include $(srcdir)/../../../Makefile.shared

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host


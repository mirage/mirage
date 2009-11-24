## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I$(srcdir)/../include $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

LIB_SOURCES = \
	s_cacos.c    s_casinf.c   s_catanh.c   s_ccosh.c   s_clog.c     s_cpowf.c   s_csinh.c   s_ctan.c \
	s_cacosf.c   s_casinh.c   s_catanhf.c  s_ccoshf.c  s_clog10.c   s_csinhf.c  s_ctanf.c \
	s_cacosh.c   s_casinhf.c  s_clog10f.c  s_cproj.c   s_ctanh.c \
	s_cacoshf.c  s_cprojf.c  s_ctanhf.c \
	s_cexp.c    s_clogf.c    s_csqrt.c  \
	s_catan.c    s_ccos.c     s_cexpf.c   s_csin.c    s_csqrtf.c  \
	s_casin.c    s_catanf.c   s_ccosf.c    s_cpow.c     s_csinf.c   

libcmath_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libcmath.la
libcmath_la_SOURCES = $(LIB_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(LIB_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../../../Makefile.shared

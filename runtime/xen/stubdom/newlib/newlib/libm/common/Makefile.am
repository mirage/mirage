## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

src = 	s_finite.c s_copysign.c s_modf.c s_scalbn.c \
	s_cbrt.c s_exp10.c s_expm1.c s_ilogb.c s_infconst.c \
	s_infinity.c s_isinf.c s_isinfd.c s_isnan.c s_isnand.c \
	s_log1p.c s_nan.c s_nextafter.c s_pow10.c \
	s_rint.c s_logb.c s_matherr.c s_lib_ver.c \
	s_fdim.c s_fma.c s_fmax.c s_fmin.c s_fpclassify.c s_lrint.c \
	s_lround.c s_nearbyint.c s_remquo.c s_round.c s_scalbln.c \
	s_signbit.c s_trunc.c

fsrc =	sf_finite.c sf_copysign.c sf_modf.c sf_scalbn.c \
	sf_cbrt.c sf_exp10.c sf_expm1.c sf_ilogb.c \
	sf_infinity.c sf_isinf.c sf_isinff.c sf_isnan.c sf_isnanf.c \
	sf_log1p.c sf_nan.c sf_nextafter.c sf_pow10.c \
	sf_rint.c sf_logb.c \
	sf_fdim.c sf_fma.c sf_fmax.c sf_fmin.c sf_fpclassify.c sf_lrint.c \
	sf_lround.c sf_nearbyint.c sf_remquo.c sf_round.c \
	sf_scalbln.c sf_trunc.c

libcommon_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libcommon.la
libcommon_la_SOURCES = $(src) $(fsrc)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(src) $(fsrc)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared

chobj =	scbrt.def scopysign.def sexp10.def sexpm1.def silogb.def \
	sinfinity.def sisnan.def slog1p.def smatherr.def smodf.def \
	snan.def snextafter.def spow10.def sscalbn.def

SUFFIXES = .def

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(chobj)

CLEANFILES = $(chobj) *.ref

# Texinfo does not appear to support underscores in file names, so we
# name the .def files without underscores.

scopysign.def: s_copysign.c
	$(CHEW) < $(srcdir)/s_copysign.c >$@ 2>/dev/null
	touch stmp-def

scbrt.def: s_cbrt.c
	$(CHEW) < $(srcdir)/s_cbrt.c >$@ 2>/dev/null
	touch stmp-def

serf.def: s_erf.c
	$(CHEW) < $(srcdir)/s_serf.c >$@ 2>/dev/null
	touch stmp-def

sexp10.def: s_exp10.c
	$(CHEW) < $(srcdir)/s_exp10.c >$@ 2>/dev/null
	touch stmp-def

sexpm1.def: s_expm1.c
	$(CHEW) < $(srcdir)/s_expm1.c >$@ 2>/dev/null
	touch stmp-def

silogb.def: s_ilogb.c
	$(CHEW) < $(srcdir)/s_ilogb.c >$@ 2>/dev/null
	touch stmp-def

sinfinity.def: s_infinity.c
	$(CHEW) < $(srcdir)/s_infinity.c >$@ 2>/dev/null
	touch stmp-def

sisnan.def: s_isnan.c
	$(CHEW) < $(srcdir)/s_isnan.c >$@ 2>/dev/null
	touch stmp-def

slog1p.def: s_log1p.c
	$(CHEW) < $(srcdir)/s_log1p.c >$@ 2>/dev/null
	touch stmp-def

smodf.def: s_modf.c
	$(CHEW) < $(srcdir)/s_modf.c >$@ 2>/dev/null
	touch stmp-def

smatherr.def: s_matherr.c
	$(CHEW) < $(srcdir)/s_matherr.c >$@ 2>/dev/null
	touch stmp-def

snan.def: s_nan.c
	$(CHEW) < $(srcdir)/s_nan.c >$@ 2>/dev/null
	touch stmp-def

snextafter.def: s_nextafter.c
	$(CHEW) < $(srcdir)/s_nextafter.c >$@ 2>/dev/null
	touch stmp-def

spow10.def: s_pow10.c
	$(CHEW) < $(srcdir)/s_pow10.c >$@ 2>/dev/null
	touch stmp-def

sscalbn.def: s_scalbn.c
	$(CHEW) < $(srcdir)/s_scalbn.c >$@ 2>/dev/null
	touch stmp-def

# A partial dependency list.

$(lib_a_OBJECTS): $(srcdir)/../../libc/include/math.h fdlibm.h

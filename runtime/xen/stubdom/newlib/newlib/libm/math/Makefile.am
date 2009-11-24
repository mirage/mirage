## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I$(srcdir)/../common $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

src = 	k_standard.c k_rem_pio2.c \
	k_cos.c k_sin.c k_tan.c \
	e_acos.c e_acosh.c e_asin.c e_atan2.c \
	e_atanh.c e_cosh.c e_exp.c e_fmod.c \
	er_gamma.c e_hypot.c e_j0.c \
	e_j1.c e_jn.c er_lgamma.c \
	e_log.c e_log10.c e_pow.c e_rem_pio2.c e_remainder.c \
	e_scalb.c e_sinh.c e_sqrt.c \
	w_acos.c w_acosh.c w_asin.c w_atan2.c \
	w_atanh.c w_cosh.c w_exp.c w_fmod.c \
	w_gamma.c wr_gamma.c w_hypot.c w_j0.c \
	w_j1.c w_jn.c w_lgamma.c wr_lgamma.c \
	w_log.c w_log10.c w_pow.c w_remainder.c \
	w_scalb.c w_sinh.c w_sqrt.c \
	w_sincos.c \
	w_cabs.c w_drem.c \
	s_asinh.c s_atan.c s_ceil.c \
	s_cos.c s_erf.c s_fabs.c s_floor.c \
	s_frexp.c s_ldexp.c \
	s_signif.c s_sin.c \
	s_tan.c s_tanh.c \
	w_exp2.c w_tgamma.c

fsrc =	kf_rem_pio2.c \
	kf_cos.c kf_sin.c kf_tan.c \
	ef_acos.c ef_acosh.c ef_asin.c ef_atan2.c \
	ef_atanh.c ef_cosh.c ef_exp.c ef_fmod.c \
	erf_gamma.c ef_hypot.c ef_j0.c \
	ef_j1.c ef_jn.c erf_lgamma.c \
	ef_log.c ef_log10.c ef_pow.c ef_rem_pio2.c ef_remainder.c \
	ef_scalb.c ef_sinh.c ef_sqrt.c \
	wf_acos.c wf_acosh.c wf_asin.c wf_atan2.c \
	wf_atanh.c wf_cosh.c wf_exp.c wf_fmod.c \
	wf_gamma.c wrf_gamma.c wf_hypot.c wf_j0.c \
	wf_j1.c wf_jn.c wf_lgamma.c wrf_lgamma.c \
	wf_log.c wf_log10.c wf_pow.c wf_remainder.c \
	wf_scalb.c wf_sinh.c wf_sqrt.c \
	wf_sincos.c \
	wf_cabs.c wf_drem.c \
	sf_asinh.c sf_atan.c sf_ceil.c \
	sf_cos.c sf_erf.c sf_fabs.c sf_floor.c \
	sf_frexp.c sf_ldexp.c \
	sf_signif.c sf_sin.c \
	sf_tan.c sf_tanh.c \
	wf_exp2.c wf_tgamma.c

libmath_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libmath.la
libmath_la_SOURCES = $(src) $(fsrc)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(src) $(fsrc)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared

chobj =	wacos.def wacosh.def wasin.def sasinh.def \
	satan.def watan2.def watanh.def wj0.def \
	wcosh.def serf.def wexp.def \
	sfabs.def sfloor.def wfmod.def sfrexp.def \
	wgamma.def whypot.def sldexp.def wlog.def \
	wlog10.def \
	wpow.def wremainder.def ssin.def wsinh.def \
	wsqrt.def stan.def stanh.def

SUFFIXES = .def

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(chobj)
	cat $(srcdir)/math.tex >> $(TARGETDOC)

CLEANFILES = $(chobj) *.ref

# Texinfo does not appear to support underscores in file names, so we
# name the .def files without underscores.

wacos.def: w_acos.c
	$(CHEW) < $(srcdir)/w_acos.c >$@ 2>/dev/null
	touch stmp-def
wacosh.def: w_acosh.c
	$(CHEW) < $(srcdir)/w_acosh.c >$@ 2>/dev/null
	touch stmp-def
wasin.def: w_asin.c
	$(CHEW) < $(srcdir)/w_asin.c >$@ 2>/dev/null
	touch stmp-def
sasinh.def: s_asinh.c
	$(CHEW) < $(srcdir)/s_asinh.c >$@ 2>/dev/null
	touch stmp-def
satan.def: s_atan.c
	$(CHEW) < $(srcdir)/s_atan.c >$@ 2>/dev/null
	touch stmp-def
watan2.def: w_atan2.c
	$(CHEW) < $(srcdir)/w_atan2.c >$@ 2>/dev/null
	touch stmp-def
watanh.def: w_atanh.c
	$(CHEW) < $(srcdir)/w_atanh.c >$@ 2>/dev/null
	touch stmp-def
wj0.def: w_j0.c
	$(CHEW) < $(srcdir)/w_j0.c >$@ 2>/dev/null
	touch stmp-def
scopysign.def: s_copysign.c
	$(CHEW) < $(srcdir)/../common/s_copysign.c >$@ 2>/dev/null
	touch stmp-def
wcosh.def: w_cosh.c
	$(CHEW) < $(srcdir)/w_cosh.c >$@ 2>/dev/null
	touch stmp-def
serf.def: s_erf.c
	$(CHEW) < $(srcdir)/s_erf.c >$@ 2>/dev/null
	touch stmp-def
wexp.def: w_exp.c
	$(CHEW) < $(srcdir)/w_exp.c >$@ 2>/dev/null
	touch stmp-def
sfabs.def: s_fabs.c
	$(CHEW) < $(srcdir)/s_fabs.c >$@ 2>/dev/null
	touch stmp-def
sfloor.def: s_floor.c
	$(CHEW) < $(srcdir)/s_floor.c >$@ 2>/dev/null
	touch stmp-def
wfmod.def: w_fmod.c
	$(CHEW) < $(srcdir)/w_fmod.c >$@ 2>/dev/null
	touch stmp-def
sfrexp.def: s_frexp.c
	$(CHEW) < $(srcdir)/s_frexp.c >$@ 2>/dev/null
	touch stmp-def
wgamma.def: w_gamma.c
	$(CHEW) < $(srcdir)/w_gamma.c >$@ 2>/dev/null
	touch stmp-def
whypot.def: w_hypot.c
	$(CHEW) < $(srcdir)/w_hypot.c >$@ 2>/dev/null
	touch stmp-def
sldexp.def: s_ldexp.c
	$(CHEW) < $(srcdir)/s_ldexp.c >$@ 2>/dev/null
	touch stmp-def
wlog.def: w_log.c
	$(CHEW) < $(srcdir)/w_log.c >$@ 2>/dev/null
	touch stmp-def
wlog10.def: w_log10.c
	$(CHEW) < $(srcdir)/w_log10.c >$@ 2>/dev/null
	touch stmp-def
wpow.def: w_pow.c
	$(CHEW) < $(srcdir)/w_pow.c >$@ 2>/dev/null
	touch stmp-def
wremainder.def: w_remainder.c
	$(CHEW) < $(srcdir)/w_remainder.c >$@ 2>/dev/null
	touch stmp-def
ssin.def: s_sin.c
	$(CHEW) < $(srcdir)/s_sin.c >$@ 2>/dev/null
	touch stmp-def
wsinh.def: w_sinh.c
	$(CHEW) < $(srcdir)/w_sinh.c >$@ 2>/dev/null
	touch stmp-def
wsqrt.def: w_sqrt.c
	$(CHEW) < $(srcdir)/w_sqrt.c >$@ 2>/dev/null
	touch stmp-def
stan.def: s_tan.c
	$(CHEW) < $(srcdir)/s_tan.c >$@ 2>/dev/null
	touch stmp-def
stanh.def: s_tanh.c
	$(CHEW) < $(srcdir)/s_tanh.c >$@ 2>/dev/null
	touch stmp-def

# A partial dependency list.

$(lib_a_OBJECTS): $(srcdir)/../../libc/include/math.h $(srcdir)/../common/fdlibm.h

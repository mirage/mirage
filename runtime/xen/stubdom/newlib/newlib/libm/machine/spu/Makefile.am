## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I $(newlib_basedir)/../newlib/libm/common $(NEWLIB_CFLAGS) \
	$(CROSS_CFLAGS) $(TARGET_CFLAGS)

LIB_SOURCES = \
	feclearexcept.c fe_dfl_env.c fegetenv.c fegetexceptflag.c \
	fegetround.c feholdexcept.c feraiseexcept.c fesetenv.c \
	fesetexceptflag.c fesetround.c fetestexcept.c feupdateenv.c \
	llrint.c llrintf.c llround.c llroundf.c log2.c log2f.c s_asinh.c \
	s_atan.c s_cbrt.c s_ceil.c s_copysign.c s_cos.c s_erf.c s_expm1.c \
	s_fabs.c sf_asinh.c sf_atan.c sf_cbrt.c sf_ceil.c sf_copysign.c \
	sf_cos.c s_fdim.c sf_erf.c sf_expm1.c sf_fabs.c sf_fdim.c \
	sf_finite.c sf_floor.c sf_fma.c sf_fmax.c sf_fmin.c \
	sf_fpclassify.c sf_frexp.c sf_ilogb.c sf_isinf.c sf_isinff.c \
	sf_isnan.c sf_isnanf.c sf_ldexp.c sf_log1p.c sf_logb.c s_floor.c \
	sf_lrint.c sf_lround.c s_fma.c s_fmax.c s_fmin.c sf_nan.c \
	sf_nearbyint.c sf_nextafter.c sf_remquo.c s_frexp.c sf_rint.c \
	sf_round.c sf_scalbn.c sf_sin.c sf_tan.c sf_tanh.c sf_trunc.c \
	s_ilogb.c s_isnan.c s_ldexp.c s_log1p.c s_lrint.c s_lround.c \
	s_nearbyint.c s_nextafter.c s_remquo.c s_rint.c s_round.c \
	s_scalbn.c s_sin.c s_tan.c s_tanh.c s_trunc.c w_acos.c w_acosh.c \
	w_asin.c w_atan2.c w_atanh.c w_cosh.c w_exp2.c w_exp.c wf_acos.c \
	wf_acosh.c wf_asin.c wf_atan2.c wf_atanh.c wf_cosh.c wf_exp2.c \
	wf_exp.c wf_fmod.c wf_hypot.c wf_lgamma.c wf_log10.c wf_log.c \
	w_fmod.c wf_pow.c wf_remainder.c wf_sincos.c wf_sinh.c wf_sqrt.c \
	wf_tgamma.c w_hypot.c w_lgamma.c w_log10.c w_log.c w_pow.c \
	w_remainder.c w_sincos.c w_sinh.c w_sqrt.c w_tgamma.c

noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(LIB_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
noinst_DATA =

include $(srcdir)/../../../Makefile.shared

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

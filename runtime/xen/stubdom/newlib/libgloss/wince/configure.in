dnl Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)

AC_INIT(Makefile.in)
AC_CANONICAL_SYSTEM
AC_ARG_PROGRAM
AM_INIT_AUTOMAKE(wince-stub, 1.0)
AM_MAINTAINER_MODE

cross_compiling=yes
program_transform_name=s,^,@target_alias@-,;

: ${CFLAGS='-O2'}
LIB_AC_PROG_CC
# CFLAGS="$CFLAGS -Xlinker --defsym -Xlinker _main=_WinMain"
AC_CHECK_TOOL(LD, ld, ld)
AC_SUBST(LD)
AC_PROG_INSTALL
case "${target}" in
    *arm*-*-*)	LDADD='-lwinsock -lsslsock' ;;
    *)		LDADD='-lwinsock'
esac
AC_SUBST(LDADD)
LIB_AM_PROG_AS
#
# The following is sort of a kludge but we *know* that we need
# an executable extension and, currently, the sh-pe-gcc compiler
# doesn't play well with configure, so, set a "cache" entry.
#
: ${ac_cv_exeext='.exe'}
AC_EXEEXT

AC_OUTPUT([Makefile])

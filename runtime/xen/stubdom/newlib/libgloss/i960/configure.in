dnl Process this file with autoconf to produce a configure script.
AC_PREREQ(2.59)
AC_INIT(crt0.c)

AC_CANONICAL_SYSTEM
AC_ARG_PROGRAM

if test "$srcdir" = "." ; then
  mdir=`echo "${with_multisubdir}/" \
    | sed -e 's,\([[^/]][[^/]]*\),..,g' -e 's,^/$,,'`
  AC_CONFIG_AUX_DIR(${mdir}../../..)
else
  AC_CONFIG_AUX_DIR(${srcdir}/../..)
fi

AC_PROG_INSTALL

LIB_AC_PROG_CC
AS=${AS-as}
AC_SUBST(AS)
AR=${AR-ar}
AC_SUBST(AR)
LD=${LD-ld}
AC_SUBST(LD)
AC_PROG_RANLIB
LIB_AM_PROG_AS

host_makefile_frag=${srcdir}/../config/default.mh

dnl We have to assign the same value to other variables because autoconf
dnl doesn't provide a mechanism to substitute a replacement keyword with
dnl arbitrary data or pathnames.
dnl
host_makefile_frag_path=$host_makefile_frag
AC_SUBST(host_makefile_frag_path)
AC_SUBST_FILE(host_makefile_frag)

AC_CONFIG_FILES(Makefile)
AC_OUTPUT

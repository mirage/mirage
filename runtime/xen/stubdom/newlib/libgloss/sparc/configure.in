# Copyright (c) 1995, 1996 Cygnus Support
#
# The authors hereby grant permission to use, copy, modify, distribute,
# and license this software and its documentation for any purpose, provided
# that existing copyright notices are retained in all copies and that this
# notice is included verbatim in any distributions. No written agreement,
# license, or royalty fee is required for any of the authorized uses.
# Modifications to this software may be copyrighted by their authors
# and need not follow the licensing terms described here, provided that
# the new terms are clearly indicated on the first page of each file where
# they apply.
dnl Process this file with autoconf to produce a configure script.
AC_PREREQ(2.59)
AC_INIT(sparc-stub.c)

if test "${enable_shared}" = "yes" ; then
    echo "Shared libraries not supported for cross compiling, ignored"
fi

if test "$srcdir" = "." ; then
  if test "${with_target_subdir}" != "." ; then
    libgloss_topdir="${with_multisrctop}../../.."
  else
    libgloss_topdir="${with_multisrctop}../.."
  fi
else
  libgloss_topdir="${srcdir}/../.."
fi

AC_CONFIG_AUX_DIR($libgloss_topdir)

AC_PROG_INSTALL

AC_CANONICAL_SYSTEM

LIB_AC_PROG_CC
AS=${AS-as}
AC_SUBST(AS)
AR=${AR-ar}
AC_SUBST(AR)
LD=${LD-ld}
AC_SUBST(LD)
AC_PROG_RANLIB
LIB_AM_PROG_AS

case ${target_cpu} in
sparclite*) CPU=SLITE ;;
sparclet*) CPU=SPLET ;;
sparc64*) CPU=SPARC64 ;;
sparc86x*) CPU=SLITE ;;
*) CPU=SPARC ;;
esac
AC_SUBST(CPU)

case ${target_cpu} in
sparc64*) CYGMONLDSCRIPTTEMPL=${srcdir}/cygmon-sparc64-ld.src ;;
sparclet-*-aout*) CYGMONLDSCRIPTTEMPL-${srcdir}/cygmon.ld.src; AC_CONFIG_SUBDIRS(libsys) ;;
*) CYGMONLDSCRIPTTEMPL=${srcdir}/cygmon.ld.src
esac

host_makefile_frag=${srcdir}/../config/default.mh
target_makefile_frag=${srcdir}/../config/default.mt

dnl We have to assign the same value to other variables because autoconf
dnl doesn't provide a mechanism to substitute a replacement keyword with
dnl arbitrary data or pathnames.
dnl
host_makefile_frag_path=$host_makefile_frag
AC_SUBST(host_makefile_frag_path)
AC_SUBST_FILE(host_makefile_frag)
target_makefile_frag_path=$target_makefile_frag
AC_SUBST(target_makefile_frag_path)
AC_SUBST_FILE(target_makefile_frag)
AC_SUBST(CYGMONLDSCRIPTTEMPL)

AC_OUTPUT(Makefile,
. ${libgloss_topdir}/config-ml.in,
srcdir=${srcdir}
target=${target}
with_multisubdir=${with_multisubdir}
ac_configure_args="${ac_configure_args} --enable-multilib"
CONFIG_SHELL=${CONFIG_SHELL-/bin/sh}
libgloss_topdir=${libgloss_topdir}
)


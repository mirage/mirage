dnl Copyright (c) 2000-2007  Red Hat, Inc. All rights reserved.
dnl
dnl This copyrighted material is made available to anyone wishing to use, 
dnl modify, copy, or redistribute it subject to the terms and conditions of 
dnl the BSD License.  This program is distributed in the hope that 
dnl it will be useful, but WITHOUT ANY WARRANTY expressed or implied, 
dnl including the implied warranties of MERCHANTABILITY or FITNESS FOR A 
dnl PARTICULAR PURPOSE.  A copy of this license is available at 
dnl http://www.opensource.org/licenses. Any Red Hat trademarks that are 
dnl incorporated in the source code or documentation are not subject to the 
dnl BSD License and may only be used or replicated with the express permission 
dnl of Red Hat, Inc.

dnl Process this file with autoconf to produce a configure script.
AC_PREREQ(2.59)
AC_INIT(crt0.S)

if test "${enable_shared}" = "yes" ; then
    echo "Shared libraries not supported for cross compiling, ignored"
fi

if test "$srcdir" = "." ; then
  if test "${with_target_subdir}" != "." ; then
    libgloss_topdir="${srcdir}/${with_multisrctop}../../.."
  else
    libgloss_topdir="${srcdir}/${with_multisrctop}../.."
  fi
else
  libgloss_topdir="${srcdir}/../.."
fi
AC_CONFIG_AUX_DIR($libgloss_topdir)

AC_CANONICAL_SYSTEM
AC_ARG_PROGRAM

AC_PROG_INSTALL

LIB_AC_PROG_CC
AS=${AS-as}
AC_SUBST(AS)
AR=${AR-ar}
AC_SUBST(AR)
LD=${LD-ld}
AC_SUBST(LD)
AC_PROG_RANLIB

host_makefile_frag=${srcdir}/../config/default.mh

dnl We have to assign the same value to other variables because autoconf
dnl doesn't provide a mechanism to substitute a replacement keyword with
dnl arbitrary data or pathnames.
dnl
host_makefile_frag_path=$host_makefile_frag
AC_SUBST(host_makefile_frag_path)
AC_SUBST_FILE(host_makefile_frag)

AC_CONFIG_FILES([Makefile],
. ${libgloss_topdir}/config-ml.in,
srcdir=${srcdir}
target=${target}
with_multisubdir=${with_multisubdir}
ac_configure_args="${ac_configure_args} --enable-multilib"
CONFIG_SHELL=${CONFIG_SHELL-/bin/sh}
libgloss_topdir=${libgloss_topdir}
)
AC_OUTPUT

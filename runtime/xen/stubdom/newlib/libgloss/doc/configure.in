dnl Process this file with autoconf to produce a configure script.
AC_PREREQ(2.59)
AC_INIT(porting.texi)

if test "$srcdir" = "." ; then
  mdir=`echo "${with_multisubdir}/" \
    | sed -e 's,\([[^/]][[^/]]*\),..,g' -e 's,^/$,,'`
  AC_CONFIG_AUX_DIR(${mdir}../../..)
else
  AC_CONFIG_AUX_DIR(${srcdir}/../..)
fi

AC_PROG_INSTALL

AC_CONFIG_FILES(Makefile)
AC_OUTPUT

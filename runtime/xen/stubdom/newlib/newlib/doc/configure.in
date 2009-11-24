dnl This is the newlib/doc configure.in file.
dnl Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)
AC_INIT([newlib],[NEWLIB_VERSION])
AC_CONFIG_SRCDIR([makedoc.c])

dnl Can't be done in NEWLIB_CONFIGURE because that confuses automake. 
AC_CONFIG_AUX_DIR(../..)

NEWLIB_CONFIGURE(..)

# Put a plausible default for CC_FOR_BUILD in Makefile.
if test -z "$CC_FOR_BUILD"; then
  if test "x$cross_compiling" = "xno"; then
    CC_FOR_BUILD='$(CC)'
  else
    CC_FOR_BUILD=gcc
  fi
fi
AC_SUBST(CC_FOR_BUILD)

# Also set EXEEXT_FOR_BUILD.
if test "x$cross_compiling" = "xno"; then
  EXEEXT_FOR_BUILD='$(EXEEXT)'
else
  AC_CACHE_CHECK([for build system executable suffix], newlib_cv_build_exeext,
    [cat > ac_c_test.c << 'EOF'
int main() {
/* Nothing needed here */
}
EOF
    ${CC_FOR_BUILD} -o ac_c_test am_c_test.c 1>&5 2>&5
    newlib_cv_build_exeext=`echo ac_c_test.* | grep -v ac_c_test.c | sed -e s/ac_c_test//`
    rm -f ac_c_test*
    test x"${newlib_cv_build_exeext}" = x && newlib_cv_build_exeext=no])
  EXEEXT_FOR_BUILD=""
  test x"${newlib_cv_build_exeext}" != xno && EXEEXT_FOR_BUILD=${newlib_cv_build_exeext}
fi
AC_SUBST(EXEEXT_FOR_BUILD)

AC_CONFIG_FILES([Makefile])
AC_OUTPUT

dnl This provides configure definitions used by all the newlib
dnl configure.in files.

AC_DEFUN([DEF_NEWLIB_VERSION],
m4_define([NEWLIB_VERSION],[1.16.0]))

dnl Basic newlib configury.  This calls basic introductory stuff,
dnl including AM_INIT_AUTOMAKE and AC_CANONICAL_HOST.  It also runs
dnl configure.host.  The only argument is the relative path to the top
dnl newlib directory.

AC_DEFUN([NEWLIB_CONFIGURE],
[AC_REQUIRE([DEF_NEWLIB_VERSION])
dnl Default to --enable-multilib
AC_ARG_ENABLE(multilib,
[  --enable-multilib         build many library versions (default)],
[case "${enableval}" in
  yes) multilib=yes ;;
  no)  multilib=no ;;
  *)   AC_MSG_ERROR(bad value ${enableval} for multilib option) ;;
 esac], [multilib=yes])dnl

dnl Support --enable-target-optspace
AC_ARG_ENABLE(target-optspace,
[  --enable-target-optspace  optimize for space],
[case "${enableval}" in
  yes) target_optspace=yes ;;
  no)  target_optspace=no ;;
  *)   AC_MSG_ERROR(bad value ${enableval} for target-optspace option) ;;
 esac], [target_optspace=])dnl

dnl Support --enable-malloc-debugging - currently only supported for Cygwin
AC_ARG_ENABLE(malloc-debugging,
[  --enable-malloc-debugging indicate malloc debugging requested],
[case "${enableval}" in
  yes) malloc_debugging=yes ;;
  no)  malloc_debugging=no ;;
  *)   AC_MSG_ERROR(bad value ${enableval} for malloc-debugging option) ;;
 esac], [malloc_debugging=])dnl

dnl Support --enable-newlib-multithread
AC_ARG_ENABLE(newlib-multithread,
[  --enable-newlib-multithread        enable support for multiple threads],
[case "${enableval}" in
  yes) newlib_multithread=yes ;;
  no)  newlib_multithread=no ;;
  *)   AC_MSG_ERROR(bad value ${enableval} for newlib-multithread option) ;;
 esac], [newlib_multithread=yes])dnl

dnl Support --enable-newlib-iconv
AC_ARG_ENABLE(newlib-iconv,
[  --enable-newlib-iconv     enable iconv library support],
[if test "${newlib_iconv+set}" != set; then
   case "${enableval}" in
     yes) newlib_iconv=yes ;;
     no)  newlib_iconv=no ;;
     *)   AC_MSG_ERROR(bad value ${enableval} for newlib-iconv option) ;;
   esac
 fi], [newlib_iconv=${newlib_iconv}])dnl

dnl Support --enable-newlib-elix-level
AC_ARG_ENABLE(newlib-elix-level,
[  --enable-newlib-elix-level         supply desired elix library level (1-4)],
[case "${enableval}" in
  0)   newlib_elix_level=0 ;;
  1)   newlib_elix_level=1 ;;
  2)   newlib_elix_level=2 ;;
  3)   newlib_elix_level=3 ;;
  4)   newlib_elix_level=4 ;;
  *)   AC_MSG_ERROR(bad value ${enableval} for newlib-elix-level option) ;;
 esac], [newlib_elix_level=0])dnl

dnl Support --disable-newlib-io-float
AC_ARG_ENABLE(newlib-io-float,
[  --disable-newlib-io-float disable printf/scanf family float support],
[case "${enableval}" in
  yes) newlib_io_float=yes ;;
  no)  newlib_io_float=no ;;
  *)   AC_MSG_ERROR(bad value ${enableval} for newlib-io-float option) ;;
 esac], [newlib_io_float=yes])dnl

dnl Support --disable-newlib-supplied-syscalls
AC_ARG_ENABLE(newlib-supplied-syscalls,
[  --disable-newlib-supplied-syscalls disable newlib from supplying syscalls],
[case "${enableval}" in
  yes) newlib_may_supply_syscalls=yes ;;
  no)  newlib_may_supply_syscalls=no ;;
  *)   AC_MSG_ERROR(bad value ${enableval} for newlib-supplied-syscalls option) ;;
 esac], [newlib_may_supply_syscalls=yes])dnl

AM_CONDITIONAL(MAY_SUPPLY_SYSCALLS, test x[$]{newlib_may_supply_syscalls} = xyes)

dnl We may get other options which we don't document:
dnl --with-target-subdir, --with-multisrctop, --with-multisubdir

test -z "[$]{with_target_subdir}" && with_target_subdir=.

if test "[$]{srcdir}" = "."; then
  if test "[$]{with_target_subdir}" != "."; then
    newlib_basedir="[$]{srcdir}/[$]{with_multisrctop}../$1"
  else
    newlib_basedir="[$]{srcdir}/[$]{with_multisrctop}$1"
  fi
else
  newlib_basedir="[$]{srcdir}/$1"
fi
AC_SUBST(newlib_basedir)

AC_CANONICAL_HOST

AM_INIT_AUTOMAKE([cygnus no-define 1.9.5])

# FIXME: We temporarily define our own version of AC_PROG_CC.  This is
# copied from autoconf 2.12, but does not call AC_PROG_CC_WORKS.  We
# are probably using a cross compiler, which will not be able to fully
# link an executable.  This should really be fixed in autoconf
# itself.

AC_DEFUN([LIB_AC_PROG_CC_GNU],
[AC_CACHE_CHECK(whether we are using GNU C, ac_cv_prog_gcc,
[dnl The semicolon is to pacify NeXT's syntax-checking cpp.
cat > conftest.c <<EOF
#ifdef __GNUC__
  yes;
#endif
EOF
if AC_TRY_COMMAND(${CC-cc} -E conftest.c) | egrep yes >/dev/null 2>&1; then
  ac_cv_prog_gcc=yes
else
  ac_cv_prog_gcc=no
fi])])

AC_DEFUN([LIB_AM_PROG_AS],
[# By default we simply use the C compiler to build assembly code.
AC_REQUIRE([LIB_AC_PROG_CC])
test "${CCAS+set}" = set || CCAS=$CC
test "${CCASFLAGS+set}" = set || CCASFLAGS=$CFLAGS
AC_ARG_VAR([CCAS],      [assembler compiler command (defaults to CC)])
AC_ARG_VAR([CCASFLAGS], [assembler compiler flags (defaults to CFLAGS)])
])

AC_DEFUN([LIB_AC_PROG_CC],
[AC_BEFORE([$0], [AC_PROG_CPP])dnl
AC_CHECK_PROG(CC, gcc, gcc)
_AM_DEPENDENCIES(CC)
if test -z "$CC"; then
  AC_CHECK_PROG(CC, cc, cc, , , /usr/ucb/cc)
  test -z "$CC" && AC_MSG_ERROR([no acceptable cc found in \$PATH])
fi

LIB_AC_PROG_CC_GNU

if test $ac_cv_prog_gcc = yes; then
  GCC=yes
dnl Check whether -g works, even if CFLAGS is set, in case the package
dnl plays around with CFLAGS (such as to build both debugging and
dnl normal versions of a library), tasteless as that idea is.
  ac_test_CFLAGS="${CFLAGS+set}"
  ac_save_CFLAGS="$CFLAGS"
  CFLAGS=
  _AC_PROG_CC_G
  if test "$ac_test_CFLAGS" = set; then
    CFLAGS="$ac_save_CFLAGS"
  elif test $ac_cv_prog_cc_g = yes; then
    CFLAGS="-g -O2"
  else
    CFLAGS="-O2"
  fi
else
  GCC=
  test "${CFLAGS+set}" = set || CFLAGS="-g"
fi
])

LIB_AC_PROG_CC

AC_CHECK_TOOL(AS, as)
AC_CHECK_TOOL(AR, ar)
AC_CHECK_TOOL(RANLIB, ranlib, :)
AC_CHECK_TOOL(READELF, readelf, :)

AC_PROG_INSTALL

# Hack to ensure that INSTALL won't be set to "../" with autoconf 2.13.  */
ac_given_INSTALL=$INSTALL

AM_MAINTAINER_MODE
LIB_AM_PROG_AS

# We need AC_EXEEXT to keep automake happy in cygnus mode.  However,
# at least currently, we never actually build a program, so we never
# need to use $(EXEEXT).  Moreover, the test for EXEEXT normally
# fails, because we are probably configuring with a cross compiler
# which can't create executables.  So we include AC_EXEEXT to keep
# automake happy, but we don't execute it, since we don't care about
# the result.
if false; then
  AC_EXEEXT
  dummy_var=1
fi

. [$]{newlib_basedir}/configure.host

newlib_cflags="[$]{newlib_cflags} -fno-builtin"

NEWLIB_CFLAGS=${newlib_cflags}
AC_SUBST(NEWLIB_CFLAGS)

LDFLAGS=${ldflags}
AC_SUBST(LDFLAGS)

AM_CONDITIONAL(ELIX_LEVEL_0, test x[$]{newlib_elix_level} = x0)
AM_CONDITIONAL(ELIX_LEVEL_1, test x[$]{newlib_elix_level} = x1)
AM_CONDITIONAL(ELIX_LEVEL_2, test x[$]{newlib_elix_level} = x2)
AM_CONDITIONAL(ELIX_LEVEL_3, test x[$]{newlib_elix_level} = x3)
AM_CONDITIONAL(ELIX_LEVEL_4, test x[$]{newlib_elix_level} = x4)

AM_CONDITIONAL(USE_LIBTOOL, test x[$]{use_libtool} = xyes)

# Hard-code OBJEXT.  Normally it is set by AC_OBJEXT, but we
# use oext, which is set in configure.host based on the target platform.
OBJEXT=${oext}

AC_SUBST(OBJEXT)
AC_SUBST(oext)
AC_SUBST(aext)
AC_SUBST(lpfx)

AC_SUBST(libm_machine_dir)
AC_SUBST(machine_dir)
AC_SUBST(sys_dir)
])

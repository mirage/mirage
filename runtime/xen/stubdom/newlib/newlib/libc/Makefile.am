## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

if HAVE_POSIX_DIR
POSIX_SUBDIR = posix
endif

if HAVE_SIGNAL_DIR
SIGNAL_SUBDIR = signal
endif

if HAVE_SYSCALL_DIR
SYSCALLS_SUBDIR = syscalls
endif

if HAVE_UNIX_DIR
UNIX_SUBDIR = unix
endif

if HAVE_STDIO_DIR
STDIO_SUBDIR = stdio
endif

if HAVE_STDIO64_DIR
STDIO64_SUBDIR = stdio64
endif

if ENABLE_NEWLIB_ICONV
NEWLIB_ICONV_DIRS = iconv
NEWLIB_ICONV_LIBS = iconv/ces/lib.$(aext) iconv/ccs/lib.$(aext) iconv/lib/lib.$(aext)
else
NEWLIB_ICONV_DIRS =
NEWLIB_ICONV_LIBS =
endif

# The order of SUBDIRS is important for the integrated documentation.
# Do not change the order without considering the doc impact.
SUBDIRS = argz stdlib ctype search $(STDIO_SUBDIR) $(STDIO64_SUBDIR) string $(SIGNAL_SUBDIR) time locale sys reent \
	$(extra_dir) errno misc machine $(UNIX_SUBDIR) $(POSIX_SUBDIR) $(SYSCALLS_SUBDIR) $(NEWLIB_ICONV_DIRS) .

noinst_DATA = $(CRT0)

if USE_LIBTOOL
noinst_LTLIBRARIES = libc.la
SUBLIBS = \
	argz/libargz.$(aext) \
	stdlib/libstdlib.$(aext) \
	ctype/libctype.$(aext) \
	search/libsearch.$(aext) \
	$(LIBC_STDIO_LIB) \
	$(LIBC_STDIO64_LIB) \
	string/libstring.$(aext) \
	$(LIBC_SIGNAL_LIB) \
	time/libtime.$(aext) \
	locale/liblocale.$(aext) \
	reent/libreent.$(aext) \
	$(LIBC_EXTRA_LIB) \
	errno/liberrno.$(aext) \
	misc/libmisc.$(aext) \
	$(LIBC_UNIX_LIB) \
	$(LIBC_POSIX_LIB) \
	$(LIBC_SYSCALL_LIB) \
	$(LIBC_MACHINE_LIB) \
	$(LIBC_SYS_LIB)
else
noinst_LIBRARIES = libc.a
SUBLIBS = \
	argz/lib.$(aext) \
	stdlib/lib.$(aext) \
	ctype/lib.$(aext) \
	search/lib.$(aext) \
	$(LIBC_STDIO_LIB) \
	$(LIBC_STDIO64_LIB) \
	string/lib.$(aext) \
	$(LIBC_SIGNAL_LIB) \
	time/lib.$(aext) \
	locale/lib.$(aext) \
	reent/lib.$(aext) \
	$(LIBC_EXTRA_LIB) \
	errno/lib.$(aext) \
	misc/lib.$(aext) \
	$(LIBC_UNIX_LIB) \
	$(LIBC_POSIX_LIB) \
	$(LIBC_SYSCALL_LIB) \
        $(NEWLIB_ICONV_LIBS) \
	$(LIBC_MACHINE_LIB) \
	$(LIBC_SYS_LIB)
endif

libc_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
libc_la_SOURCES =
libc_la_LIBADD = $(SUBLIBS)
libc_la_DEPENDENCIES = $(SUBLIBS)
else
libc.a: $(SUBLIBS)
	rm -f $@
	rm -rf tmp
	mkdir tmp
	cd tmp; \
	 for i in $(SUBLIBS); do \
	   $(AR) x ../$$i; \
	 done; \
	$(AR) $(AR_FLAGS) ../$@ *.o
	$(RANLIB) $@
	rm -rf tmp
endif # USE_LIBTOOL

$(SUBLIBS): ; @true

crt0.o: sys/crt0.o
	rm -f $@
	ln sys/crt0.o $@ >/dev/null 2>/dev/null || cp sys/crt0.o $@

sys/crt0.o: ; @true

# This is a list of the stmp-def files in each subdirectory which
# builds .def files.  We don't list subdirectories which don't build
# .def files; if the list of subdirectories changes, we must change
# this as well.
SUBDEFS = \
	stdlib/stmp-def \
	ctype/stmp-def \
	$(LIBC_STDIO_DEF) \
	$(LIBC_STDIO64_DEF) \
	string/stmp-def \
	$(LIBC_SIGNAL_DEF) \
	time/stmp-def \
	locale/stmp-def \
	reent/stmp-def \
	$(LIBC_EXTRA_DEF) \
	misc/stmp-def

libc.info: sigset.texi extra.texi stdio64.texi iconvset.texi \
	targetdep.tex $(SUBDEFS)

libc.dvi: sigset.texi extra.texi stdio64.texi iconvset.texi \
	targetdep.tex $(SUBDEFS)

stmp-sigset: config.status
	if test -n "$(LIBC_SIGNAL_LIB)"; then \
	  echo "@set SIGNALS" >tmp.texi; \
	else \
	  echo "@clear SIGNALS" >tmp.texi; \
	fi
	$(SHELL) $(newlib_basedir)/../move-if-change tmp.texi sigset.texi
	touch $@

sigset.texi: stmp-sigset ; @true

stmp-iconvset: config.status
	if test -n "$(NEWLIB_ICONV_LIBS)"; then \
	  echo "@set ICONV" >tmp.texi; \
	else \
	  echo "@clear ICONV" >tmp.texi; \
	fi
	$(SHELL) $(newlib_basedir)/../move-if-change tmp.texi iconvset.texi
	touch $@

iconvset.texi: stmp-iconvset ; @true

stmp-extra: config.status
	if test -n "$(LIBC_EXTRA_LIB)"; then \
	  echo "@set EXTRA" >tmp.texi; \
	else \
	  echo "@clear EXTRA" >tmp.texi; \
	fi
	$(SHELL) $(newlib_basedir)/../move-if-change tmp.texi extra.texi
	touch $@

extra.texi: stmp-extra ; @true

stmp-stdio64: config.status
	if test -n "$(LIBC_STDIO64_LIB)"; then \
	  echo "@set STDIO64" >tmp.texi; \
	else \
	  echo "@clear STDIO64" >tmp.texi; \
	fi
	$(SHELL) $(newlib_basedir)/../move-if-change tmp.texi stdio64.texi
	touch $@

stdio64.texi: stmp-stdio64 ; @true

stmp-targetdep: force
	rm -f tmp.texi
	targetdoc=`pwd`/tmp.texi; \
	for d in $(SUBDIRS); do \
	  if test "$$d" != "."; then \
	    (cd $$d && $(MAKE) TARGETDOC=$${targetdoc} doc) || exit 1; \
	  fi; \
	done
	cat $(srcdir)/sys.tex >>tmp.texi
	$(SHELL) $(newlib_basedir)/../move-if-change tmp.texi targetdep.tex
	touch $@

targetdep.tex: stmp-targetdep ; @true

$(SUBDEFS): stmp-targetdep ; @true

info_TEXINFOS = libc.texinfo
libc_TEXINFOS = sigset.texi extra.texi stdio64.texi iconvset.texi \
	targetdep.tex $(SUBDEFS)

.PHONY: force
force:

CLEANFILES = $(CRT0) \
	sigset.texi stmp-sigset extra.texi stmp-extra \
	stdio64.texi stmp-stdio64 tmp.texi targetdep.tex stmp-targetdep

ACLOCAL_AMFLAGS = -I .. -I ../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

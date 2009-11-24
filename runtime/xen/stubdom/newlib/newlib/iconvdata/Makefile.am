## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I$(srcdir) -I$(srcdir)/../libc/sys/linux $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

if ELIX_LEVEL_1
LIB_OBJS = 
else
LIB_OBJS = euc-jp.$(oext) jis0201.$(oext) jis0208.$(oext) jis0212.$(oext)
endif

AM_CFLAGS = -DNDEBUG

all: Makefile

pkglib_LTLIBRARIES = EUC-JP.la
EUC_JP_la_SOURCES = dummy.c
EUC_JP_la_LIBADD = $(LIB_OBJS)
EUC_JP_la_DEPENDENCIES = $(LIB_OBJS)
EUC_JP_la_LDFLAGS = -module -no-undefined -Xcompiler -Wl,-rpath-link=.. -Xcompiler -nostdlib -L.. -lc

install-data-local: install-pkglibLTLIBRARIES $(srcdir)/gconv-modules
	$(INSTALL_DATA) $(srcdir)/gconv-modules $(DESTDIR)$(pkglibdir)/gconv-modules

ACLOCAL_AMFLAGS = -I .. -I ../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

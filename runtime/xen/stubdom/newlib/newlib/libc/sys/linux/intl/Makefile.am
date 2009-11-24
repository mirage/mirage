## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I$(srcdir)/.. $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

LIB_SOURCES = \
	bindtextdom.c catgets.c dcgettext.c dgettext.c gettext.c       \
	dcigettext.c dcngettext.c dngettext.c ngettext.c open_catalog.c \
	finddomain.c lcl_stpcpy.c loadmsgcat.c localealias.c textdomain.c \
	l10nflist.c explodename.c plural.c


libintl_la_LDFLAGS = -Xcompiler -nostdlib

msgcatdir = /usr/share/locale

if USE_LIBTOOL
noinst_LTLIBRARIES = libintl.la
libintl_la_SOURCES = $(LIB_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(LIB_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA = 
endif # USE_LIBTOOL

include $(srcdir)/../../../../Makefile.shared

AM_CFLAGS = -DNOT_IN_libc -DHAVE_CONFIG_H -D_GNU_SOURCE -D__libc_enable_secure=1 -D'LOCALEDIR="$(msgcatdir)"' -D'LOCALE_ALIAS_PATH="$(msgcatdir)"' -DNLSPATH='"$(msgcatdir)/%L/%N:$(msgcatdir)/%L/LC_MESSAGES/%N:$(msgcatdir)/%l/%N:$(msgcatdir)/%l/LC_MESSAGES/%N:"'

# shouldn't have to do the following, but if needed
BISONFLAGS = --yacc --name-prefix=__gettext --output
plural.c: plural.y
	$(BISON) $(BISONFLAGS) $@ $^


## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

# We can't use noinst_PROGRAMS, because automake will add $(EXEEXT).
noinst_DATA = makedoc

MKDOC = makedoc$(EXEEXT_FOR_BUILD)

# We don't use CFLAGS with CC_FOR_BUILD because here CFLAGS will
# actually be CFLAGS_FOR_TARGET, and in some cases that will include
# -Os, which CC_FOR_BUILD may not recognize.

$(MKDOC): makedoc.o
	$(CC_FOR_BUILD) $(CFLAGS_FOR_BUILD) $(LDFLAGS) -o $(MKDOC) makedoc.o

makedoc.o: makedoc.c
	$(CC_FOR_BUILD) -g $(CFLAGS_FOR_BUILD) -c $(srcdir)/makedoc.c

ACLOCAL_AMFLAGS = -I .. -I ../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

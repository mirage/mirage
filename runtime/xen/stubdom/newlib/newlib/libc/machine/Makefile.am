## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

SUBDIRS = $(machine_dir) .

if HAVE_MACHINE_DIR
MACHLIB = lib.a
endif

if USE_LIBTOOL
else
noinst_LIBRARIES = $(MACHLIB)

lib.a: $(machine_dir)/lib.a
	rm -f $@
	ln $(machine_dir)/lib.a $@ >/dev/null 2>/dev/null || \
	 cp $(machine_dir)/lib.a $@
endif

$(machine_dir)/lib.a:

doc:

ACLOCAL_AMFLAGS = -I ../.. -I ../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

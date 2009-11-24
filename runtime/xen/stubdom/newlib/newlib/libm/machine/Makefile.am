## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

SUBDIRS = $(libm_machine_dir) .

if HAVE_LIBM_MACHINE_DIR
LIBM_MACHLIB = lib.a
endif

if USE_LIBTOOL
else
noinst_LIBRARIES = $(LIBM_MACHLIB)

lib.a: $(libm_machine_dir)/lib.a
	rm -f $@
	ln $(libm_machine_dir)/lib.a $@ >/dev/null 2>/dev/null || \
	 cp $(libm_machine_dir)/lib.a $@
endif # USE_LIBTOOL

$(libm_machine_dir)/lib.a:

doc:

ACLOCAL_AMFLAGS = -I ../.. -I ../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

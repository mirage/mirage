## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

SUBDIRS = $(sys_dir) .

if HAVE_SYS_DIR
SYSLIB = lib.a
endif

noinst_DATA = $(CRT0)

if USE_LIBTOOL
else
noinst_LIBRARIES = $(SYSLIB)

lib.a: $(sys_dir)/lib.a
	rm -f $@
	ln $(sys_dir)/lib.a $@ >/dev/null 2>/dev/null \
	 || cp $(sys_dir)/lib.a $@
endif # USE_LIBTOOL

$(sys_dir)/libsys.$(aext): ; @true

$(CRT0): $(sys_dir)/$(CRT0)
	rm -f $@
	ln $(sys_dir)/$(CRT0) $@ >/dev/null 2>/dev/null \
	 || cp $(sys_dir)/$(CRT0) $@

$(sys_dir)/$(CRT0): ; @true

CLEANFILES = $(CRT0)

doc:

ACLOCAL_AMFLAGS = -I ../.. -I ../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

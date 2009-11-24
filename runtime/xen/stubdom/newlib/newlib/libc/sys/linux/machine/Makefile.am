## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

SUBDIRS = $(machine_dir) .

noinst_DATA = $(CRT0)

$(CRT0): $(machine_dir)/$(CRT0)
	rm -f $@
	ln $(machine_dir)/$(CRT0) $@ >/dev/null 2>/dev/null \
	 || cp $(machine_dir)/$(CRT0) $@

$(machine_dir)/$(CRT0): ; @true

CLEANFILES = $(CRT0)

doc:

ACLOCAL_AMFLAGS = -I ../../../.. -I ../../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

lib_a_SOURCES = \
	_alloc.S	\
	_close.S	\
	_cycles.S	\
	_exit.S		\
	_getpsiz.S	\
	_gettz.S	\
	_ioctl.S	\
	_iostat.S	\
	_iowait.S	\
	_lseek.S	\
	_open.S		\
	_query.S	\
	_read.S		\
	_setim.S	\
	_settrap.S	\
	_setvec.S	\
	_tmpnam.S	\
	_write.S	\
	alloc.S		\
	clock.S		\
	getargs.S	\
	getenv.S	\
	read.S		\
	remove.S	\
	rename.S	\
	signal.S	\
	_sbrk.S 	\
	_fstat.S 	\
	_isatty.S 	\
	systime.S	\
	vec.S		\
	kill.c		\
	getpid.c	\
	stubs.S

lib_a_CCASFLAGS = $(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)

all: crt0.o

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

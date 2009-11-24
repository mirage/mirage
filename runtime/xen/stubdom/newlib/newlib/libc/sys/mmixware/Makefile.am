## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

lib_a_SOURCES = _exit.c access.c chmod.c chown.c close.c creat.c \
	execv.c execve.c fork.c fstat.c getpid.c isatty.c \
	kill.c link.c lseek.c open.c pipe.c read.c \
	sbrk.c stat.c time.c unlink.c utime.c wait.c write.c \
	times.c gettime.c setjmp.S
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)

all: crt0.o

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

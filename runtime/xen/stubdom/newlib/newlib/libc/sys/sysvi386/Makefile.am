## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

lib_a_SOURCES = \
	ioctl.S isatty.c read.S lseek.S close.S sbrk.c fstat.S cerror.S \
	_exit.S write.S open.S signal.S kill.S getpid.S brk.S fork.S wait.S \
	execve.S exec.c utime.S fcntl.S chmod.S getuid.S getgid.S time.S \
	stat.S link.S unlink.S rename.S mkdir.S rmdir.S sigaction.S \
	sigprocmask.S waitpid.S sysconf.S pathconf.S fpathconf.S \
	getdents.S opendir.c readdir.c rewinddir.c closedir.c pipe.S \
	getgroups.S setuid.S getuid.S setgid.S geteuid.S getegid.S \
	chdir.S dup2.c dup.c tcgetattr.c tcsetattr.c speed.c tcline.c \
	times.S pause.S sleep.c alarm.S access.S _longjmp.S _setjmp.S
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)

all: crt0.o

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

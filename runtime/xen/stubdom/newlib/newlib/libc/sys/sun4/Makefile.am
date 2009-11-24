## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

COPYOFILES = \
	Ovfork.o \
	_exit.o \
	_sigvec.o \
	abort.o \
	access.o \
	cerror.o \
	chmod.o \
	chown.o \
	close.o \
	creat.o \
	dup.o \
	dup2.o \
	errlst.o \
	execl.o \
	execle.o \
	execv.o \
	execve.o \
	execvp.o \
	fork.o \
	fstat.o \
	getdtablesize.o \
	getpid.o \
	getrusage.o  \
	gettimeofday.o \
	ieee_globals.o \
	ioctl.o \
	isatty.o \
	kill.o \
	link.o \
	lseek.o \
	open.o \
	pipe.o \
	popen.o \
	read.o \
	sbrk.o \
	setitimer.o \
	sigblock.o \
	signal.o \
	sigpause.o \
	sigsetjmp.o \
	sigsetmask.o \
	sigtramp.o \
	sigvec.o \
	sleep.o \
	start_float.o \
	stat.o \
	time.o \
	times.o \
	umask.o \
	unlink.o \
	utime.o \
	utimes.o \
	wait.o \
	wait3.o \
	wait4.o \
	write.o \
	rem.o \
	multiply.o \
	umultiply.o

# These files are from Sun's libc.a, but the must be renamed because they
# conflict with other library .o's.  They are renamed to xxxS.o.
COPYRENAMEOFILES = divS.o

COPYOMFILES = ieee_flags.o

lib_a_SOURCES = _main.c ieee.c
lib_a_LIBADD = $(COPYOFILES) $(COPYOMFILES) $(COPYRENAMEOFILES)
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)

$(COPYOFILES):
	$(AR) x /lib/libc.a $(COPYOFILES) 

$(COPYRENAMEOFILES):
	$(AR) x /lib/libc.a $(COPYRENAMEFILES:S.o=.o)
	for f in $(COPYRENAMEOFILES); do mv `basename $$f S.o`.o $$f; done

$(COPYOMFILES):
	$(AR) x /lib/libm.a $(COPYOMFILES) 

all: crt0.o

crt0.o:
	cp /lib/crt0.o crt0.o

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

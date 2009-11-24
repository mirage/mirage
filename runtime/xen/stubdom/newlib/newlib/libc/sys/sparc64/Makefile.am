## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

# _r.o is for the reentrant syscall stubs.

SUFFIXES = _r.o

.S_r.o:
	$(COMPILE) -DREENT -c $< -o $@

.c_r.o:
	$(COMPILE) -DREENT -c $< -o $@

# We no longer copy files out of /lib/libc.a.  This is kept around until
# most of them have replacements.
#
#COPYOFILES = \
#	Ovfork.o _sigvec.o abort.o access.o chown.o creat.o \
#	errlst.o getdents.o getdtablesize.o getpid.o \
#	getrusage.o gettimeofday.o ieee_globals.o ioctl.o isatty.o \
#	kill.o popen.o sbrk.o sigblock.o sigpause.o sigsetmask.o \
#	sigtramp.o sigvec.o sleep.o setitimer.o start_float.o \
#	time.o times.o utime.o utimes.o wait3.o
COPYOFILES =

# These files are from Sun's libc.a but must be renamed because they
# conflict with other library .o's. They are renamed to xxxS.o.
# div.o is used by times.o. errno.o conflicts with libc/errno/errno.o.
#COPYRENAMEOFILES = divS.o errnoS.o
COPYRENAMEOFILES =

#COPYOMFILES = ieee_flags.o
COPYOMFILES =

# CFILES_R, SFILES_R, and TEMPLATE_SFILES_R define those system calls that are
# needed by the ANSI C part of newlib (and thus we must provide namespace
# clean versions of them because we define REENTRANT_SYSCALLS_PROVIDED).

CFILES = _main.c ieee.c \
	closedir.c opendir.c readdir.c rewinddir.c scandir.c seekdir.c \
	telldir.c \
	creat.c isatty.c utime2.c

CFILES_R =

SFILES = cerror.S crt0.S dup2.S execve.S _exit.S sigsetjmp.S utime.S

SFILES_R = sbrk.S wait.S

# List of files built from template.S (with an '_' suffix).

TEMPLATE_SFILES = access_ chdir_ chmod_ chown_ dup_ fcntl_ \
	lstat_ mkdir_ pipe_ rmdir_ times_ umask_ utimes_

TEMPLATE_SFILES_R = close_ fork_ fstat_ getpid_ gettimeofday_ kill_ \
	link_ lseek_ open_ read_ stat_ times_ unlink_ wait4_ write_

OFILES = $(COPYOFILES) $(COPYRENAMEOFILES) $(COPYOMFILES) \
	$(SFILES:.S=.o) $(SFILES_R:.S=.o) $(SFILES_R:.S=_r.o) \
	$(TEMPLATE_SFILES:_=.o) $(TEMPLATE_SFILES_R:_=.o) $(TEMPLATE_SFILES_R:_=_r.o) \
	$(CFILES:.c=.o) $(CFILES_R:.c=.o) $(CFILES_R:.c=_r.o)

lib_a_SOURCES = $(SFILES) $(SFILES_R) $(CFILES) $(CFILES_R)
lib_a_LIBADD = $(COPYOFILES) $(COPYRENAMEOFILES) $(COPYOMFILES) \
	$(SFILES_R:.S=_r.o) \
	$(TEMPLATE_SFILES:_=.o) $(TEMPLATE_SFILES_R:_=.o) \
	$(TEMPLATE_SFILES_R:_=_r.o) \
	$(CFILES_R:.c=_r.o)

$(COPYOFILES):
	$(AR) x /lib/libc.a $(COPYOFILES) 

$(COPYRENAMEOFILES):
	$(AR) x /lib/libc.a $(COPYRENAMEOFILES:S.o=.o) 
	for f in $(COPYRENAMEOFILES); do mv `basename $$f S.o`.o $$f; done

$(COPYOMFILES):
	$(AR) x /lib/libm.a $(COPYOMFILES) 

stamp-srcs: Makefile template.S template_r.S
	for f in $(TEMPLATE_SFILES:_=);	do \
	  $(COMPILE) -E -Dfunc=$$f $(srcdir)/template.S >$$f.S; \
	done
	for f in $(TEMPLATE_SFILES_R:_=); do \
	  $(COMPILE) -E -Dfunc=$$f $(srcdir)/template_r.S | sed -e 's/^_/#/' >$$f.S; \
	done
	touch stamp-srcs

# Make a dependency for each file built from a template.

$(TEMPLATE_SFILES:_=.S) $(TEMPLATE_SFILES_R:_=.S): stamp-srcs

all: crt0.o

close_r.o: close.S
fork_r.o: fork.S
fstat_r.o: fstat.S
getpid_r.o: getpid.S
gettimeofday_r.o: gettimeofday.S
kill_r.o: kill.S
link_r.o: link.S
lseek_r.o: lseek.S
open_r.o: open.S
read_r.o: read.S
sbrk_r.o: sbrk.S
stat_r.o: stat.S
times_r.o: times.S
unlink_r.o: unlink.S
wait_r.o: wait.S
wait4_r.o: wait4.S
write_r.o: write.S

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

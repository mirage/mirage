## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I$(srcdir)/include $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS) $(INCLTDL)

if ELIX_LEVEL_1
argp_dir=
ARGP_LIB=
else
argp_dir=argp
ARGP_LIB=argp/libargp.la
endif

SUBDIRS = machine \
	$(argp_dir) \
	cmath \
	$(EXTRA_SUBDIRS)\
	.
SUBLIBS = \
	$(ARGP_LIB) \
	cmath/libcmath.la \
	$(EXTRA_SUBLIBS) \
	$(LINUX_MACH_LIB)

GENERAL_SOURCES = \
	aio.c \
	brk.c \
	calloc.c \
	callocr.c \
	cfreer.c \
	cfspeed.c \
	clock_getres.c \
	clock_gettime.c \
	clock_settime.c \
	flockfile.c \
	free.c \
	freer.c \
	ftok.c \
	funlockfile.c \
	getdate.c \
	getdate_err.c \
	gethostid.c \
	gethostname.c \
	getreent.c \
	ids.c \
	inode.c \
	io.c \
	ipc.c \
	linux.c \
	mallinfor.c \
	malloc.c \
	mallocr.c \
	mallstatsr.c \
	mmap.c \
	mq_close.c \
	mq_getattr.c \
	mq_notify.c \
	mq_open.c \
	mq_receive.c \
	mq_send.c \
	mq_setattr.c \
	mq_unlink.c \
	msize.c \
	msizer.c \
	mstats.c \
	mtrim.c \
	mtrimr.c \
	ntp_gettime.c \
	pread.c \
	process.c \
	prof-freq.c \
	profile.c \
	psignal.c \
	pwrite.c \
	raise.c \
	realloc.c \
	reallocr.c \
	rename.c \
	resource.c \
	sched.c \
	select.c \
	seteuid.c \
	sethostid.c \
	sethostname.c \
	shm_open.c \
	shm_unlink.c \
	sig.c \
	sigaction.c \
	sigqueue.c \
	signal.c \
	siglongjmp.c \
	sigset.c \
	sigwait.c \
	socket.c \
	sleep.c \
	strsignal.c \
	strverscmp.c \
	sysconf.c \
	sysctl.c \
	systat.c \
	tcdrain.c \
	tcsendbrk.c \
	termios.c \
	time.c \
	usleep.c \
	versionsort.c 

ELIX_2_SOURCES = \
	aio64.c \
	confstr.c \
	ctermid.c \
	fclean.c \
	fpathconf.c \
	fstab.c \
	fstatvfs.c \
	fstatvfs64.c \
	ftw.c \
	ftw64.c \
	getopt.c \
	getopt1.c \
	getrlimit64.c \
	getwd.c \
	io64.c \
	malign.c \
	malignr.c \
	malloptr.c \
	mcheck.c \
	mntent.c \
	mntent_r.c \
	pathconf.c \
	pread64.c \
	pvallocr.c \
	pwrite64.c \
	readdir64.c \
	realpath.c \
	scandir64.c \
	setrlimit64.c \
	statvfs.c \
	statvfs64.c \
	ttyname_r.c \
	utimes.c \
	vallocr.c \
	versionsort64.c

ELIX_3_SOURCES = \
	system.c \
	wait.c

ELIX_4_SOURCES = \
	getlogin.c \
	getpwent.c \
	stack.c

if ELIX_LEVEL_1
ELIX_SOURCES =
else
if ELIX_LEVEL_2
ELIX_SOURCES = $(ELIX_2_SOURCES)
else
if ELIX_LEVEL_3
ELIX_SOURCES = $(ELIX_2_SOURCES) $(ELIX_3_SOURCES)
else
ELIX_SOURCES = $(ELIX_2_SOURCES) $(ELIX_3_SOURCES) $(ELIX_4_SOURCES)
endif
endif
endif

# This will handle both /usr/src/linux-2.4/include/asm/signal.h (in Red Hat Linux 7.1)
# and also /usr/src/linux/include/asm/signal.h in older versions of Red Hat Linux
SIGNAL_H = /usr/include/asm/signal.h

liblinux_la_LDFLAGS = -Xcompiler -nostdlib

ADD_OBJS = \
	$(LINUX_MACH_LIB)

if USE_LIBTOOL
noinst_LTLIBRARIES = liblinux.la
liblinux_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
liblinux_la_LIBADD = $(ADD_OBJS)
liblinux_la_DEPENDENCIES = $(ADD_OBJS)
LIBC_COMPILE = $(LTCOMPILE)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_LIBADD = $(ADD_OBJS)
lib_a_DEPENDENCIES = $(ADD_OBJS)
lib_a_CFLAGS = $(AM_CFLAGS)
LIBC_COMPILE = $(COMPILE)
noinst_DATA =

lib.a:  $(lib_a_OBJECTS)
	rm -f $@
	rm -rf tmp
	mkdir tmp
	cd tmp; \
	for i in $(SUBLIBS); do \
	  $(AR) x ../$$i; \
	done; \
	$(AR) $(AR_FLAGS) ../$@ *.o
	$(RANLIB) $@
	rm -rf tmp

endif # USE_LIBTOOL

objectlist.awk.in: $(noinst_LTLIBRARIES) $(SUBLIBS)
	-rm -f objectlist.awk.in
	for i in `ls *.lo` ; \
	  do \
	    echo $$i `pwd`/$$i >> objectlist.awk.in ; \
	done
	for j in $(SUBLIBS) ; \
	  do \
	    export i=`echo $$j | sed -e 's,\(.*\)\/[^\/]*$$,\1,'`; \
	    if test $$i != "." && test -f $$i/objectlist.awk.in; then \
	    	cat $$i/objectlist.awk.in >> objectlist.awk.in ; \
	    fi; \
	done

all: crt0.o crt1.o

crt0.o: machine/crt0.o
	rm -f $@
	ln machine/crt0.o $@ >/dev/null 2>/dev/null || cp machine/crt0.o $@

machine/crt0.o: ; @true

$(lpfx)sig.$(oext):	siglist.inc

siglist.inc:
		$(AWK) '{ max = 32 } \
		  /#define.SIG.*[1-9][0-9]*/ { n[$$3] = $$2 } \
		  /#define.NSIG.*[1-9][0-9]*/ { max = $$3 } \
		  /#define.SIGUNUSED/ \
		    { for (i = 0; i <= max; i++) print "\"" n[i] "\"," }' \
		    < $(SIGNAL_H) > siglist.inc || \
		    { rm -f siglist.inc; exit 1; }

AM_CFLAGS = -I $(srcdir)/../../stdio
ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

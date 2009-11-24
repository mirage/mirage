## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = -I$(srcdir)/../include -I$(srcdir)/machine/$(machine_dir) -I$(srcdir)/machine/generic  $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS) -I$(srcdir)/..

LIBTOOL_VERSION_INFO = 0:0:0

LIB_SOURCES= \
	attr.c barrier.c condvar.c \
	events.c getcpuclockid.c getreent.c join.c lockfile.c manager.c \
	mq_notify.c oldsemaphore.c prio.c ptclock_gettime.c ptclock_settime.c \
	ptlongjmp.c pt-machine.c reent.c rwlock.c semaphore.c \
	signals.c spinlock.c sysctl.c \
	timer_create.c timer_getoverr.c timer_routines.c \
	timer_delete.c timer_gettime.c timer_settime.c \
	wrapsyscall.c

LIB_DB_SOURCES = td_init.c td_log.c td_ta_delete.c td_ta_get_nthreads.c      \
	td_ta_get_ph.c td_ta_map_id2thr.c td_ta_map_lwp2thr.c     \
	td_ta_new.c td_ta_thr_iter.c td_ta_tsd_iter.c		  \
	td_thr_get_info.c td_thr_getfpregs.c td_thr_getgregs.c    \
	td_thr_getxregs.c td_thr_getxregsize.c td_thr_setfpregs.c \
	td_thr_setgregs.c td_thr_setprio.c td_thr_setsigpending.c \
	td_thr_setxregs.c td_thr_sigsetmask.c td_thr_tsd.c	  \
	td_thr_validate.c td_thr_dbsuspend.c td_thr_dbresume.c    \
	td_ta_setconcurrency.c td_ta_enable_stats.c       	  \
	td_ta_reset_stats.c td_ta_get_stats.c td_ta_event_addr.c  \
	td_thr_event_enable.c td_thr_set_event.c 	          \
	td_thr_clear_event.c td_thr_event_getmsg.c		  \
	td_ta_set_event.c td_ta_event_getmsg.c		          \
	td_ta_clear_event.c td_symbol_list.c

# Because of how libtool moves objects around, these files must be built last.
LIBADD_OBJS = \
	$(lpfx)mutex.$(oext) $(lpfx)specific.$(oext) \
	$(lpfx)pthread.$(oext) $(lpfx)cancel.$(oext) 

ELIX_3_SOURCES = \
	ptfork.c

if ELIX_LEVEL_1
ELIX_SOURCES = reqsyscalls.c
else
if ELIX_LEVEL_2
ELIX_SOURCES = reqsyscalls.c
else
ELIX_SOURCES = $(ELIX_3_SOURCES)
endif
endif

SUBDIRS = machine .

tooldir = $(tooldir)
toollibdir = $(top_toollibdir)

libpthread_la_LDFLAGS = -version-info $(LIBTOOL_VERSION_INFO) -release newlib -no-undefined -lgcc -Xcompiler -nostdlib -Xlinker --version-script=$(srcdir)/../shared.ld `cat extra-libtool-objlist`
libthread_db_la_LDFLAGS = -version-info $(LIBTOOL_VERSION_INFO) -release newlib -no-undefined -lgcc -Xcompiler -nostdlib -Xlinker --version-script=$(srcdir)/../shared.ld 

if USE_LIBTOOL

# objects listed later in LIBPTHREAD_OBJLISTS will override those listed earlier
extra-libtool-objlist: $(MACHINE_OBJLIST)
	cat $(MACHINE_OBJLIST) | $(AWK) '{ libpthread[$$1] = $$2 }; END { for (x in libpthread) printf ("%s\n", libpthread[x]) }' > $@

toollib_LTLIBRARIES = libpthread.la libthread_db.la
libpthread_la_SOURCES = $(LIB_SOURCES) $(ELIX_SOURCES)
libpthread_la_LIBADD = $(LIBADD_OBJS)
## libpthread_la_DEPENDENCIES = defs.h crti.S
libpthread_la_DEPENDENCIES = $(LIBADD_OBJS) extra-libtool-objlist
noinst_DATA=objectlist.awk.in
LIB_COMPILE = $(LTCOMPILE)

libthread_db_la_SOURCES = $(LIB_DB_SOURCES)

else

toollib_LIBRARIES = libpthread.a libthread_db.a
libpthread_a_SOURCES = $(LIB_SOURCES) $(ELIX_SOURCES)
libpthread_a_LIBADD = $(LIBADD_OBJS) $(MACHINE_LIB)
libpthread_a_CFLAGS = $(AM_CFLAGS)
## libpthread_a_DEPENDENCIES = defs.h crti.S
libpthread_a_DEPENDENCIES = $(LIBADD_OBJS) $(MACHINE_LIB)
LIB_COMPILE = $(COMPILE)

libthread_db_a_SOURCES = $(LIB_DB_SOURCES)
libthread_db_a_CFLAGS = $(AM_CFLAGS)

endif # USE_LIBTOOL

include $(srcdir)/../../../../Makefile.shared

doc:

install-data-local: install-toollibLIBRARIES
	-rm -f $(DESTDIR)$(toollibdir)/libthread_db.so.1
	ln -s `readlink $(DESTDIR)$(toollibdir)/libthread_db.so` \
	  $(DESTDIR)$(toollibdir)/libthread_db.so.1 \
	  || cp $(DESTDIR)$(toollibdir)/libthread_db.so \
	  $(DESTDIR)$(toollibdir)/libthread_db.so.1 

AM_CFLAGS = -D_XOPEN_SOURCE=600 -D_GNU_SOURCE=1
ACLOCAL_AMFLAGS = -I ../../../.. -I ../../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

## PTHREAD_HEADERS=pthread.h semaphore.h

CFLAGS_pt_initfini = -g0 -fPIC -fno-inline-functions
CFLAGS_noweak=-D__NO_WEAK_PTHREAD_ALIASES
CFLAGS_cancel=-D__NO_WEAK_PTHREAD_ALIASES -D_RPC_THREAD_SAFE_
CFLAGS_pthread=-D__NO_WEAK_PTHREAD_ALIASES -DHAVE_Z_NODELETE

pt-initfini.s: $(srcdir)/pt-initfini.c
	$(CC) -S $(CFLAGS_pt_initfini) -finhibit-size-directive \
		$(patsubst -f%,-fno-%,$(exceptions)) -o $@

# We only have one kind of startup code files.  Static binaries and
# shared libraries are build using the PIC version.
crti.S: pt-initfini.s
	sed -n -e '1,/@HEADER_ENDS/p' \
	       -e '/@_.*_PROLOG_BEGINS/,/@_.*_PROLOG_ENDS/p' \
	       -e '/@TRAILER_BEGINS/,$$p' $< > $@

defs.h: pt-initfini.s
	sed -n -e '/@TESTS_BEGIN/,/@TESTS_END/p' $< | \
		$(AWK) -f defs.awk > $@

crti.o: crti.S defs.h
	$(CC) -g0 $(ASFLAGS) -o $@

$(lpfx)mutex.$(oext): $(srcdir)/mutex.c
	$(LIB_COMPILE) $(CFLAGS_noweak) -c $< -o $@

$(lpfx)specific.$(oext): $(srcdir)/specific.c
	$(LIB_COMPILE) $(CFLAGS_noweak) -c $< -o $@

$(lpfx)pthread.$(oext): $(srcdir)/pthread.c
	$(LIB_COMPILE) $(CFLAGS_pthread) -c $< -o $@

$(lpfx)ptfork.$(oext): $(srcdir)/ptfork.c
	$(LIB_COMPILE) $(CFLAGS_noweak) -c $< -o $@

$(lpfx)cancel.$(oext): $(srcdir)/cancel.c
	$(LIB_COMPILE) $(CFLAGS_cancel) -c $< -o $@


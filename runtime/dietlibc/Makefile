INSTALL=install
prefix?=/opt/diet
# Set the following to install to a different root
#DESTDIR=/tmp/fefix
# Use "make DEBUG=1" to compile a debug version.

LIBDIR=${prefix}/lib
BINDIR=${prefix}/bin
MAN1DIR=${prefix}/man/man1

MYARCH:=$(shell uname -m | sed -e 's/i[4-9]86/i386/' -e 's/armv[3-6]t\?e\?[lb]/arm/')

ARCH=x86_64

OBJDIR=bin-$(ARCH)
ILIBDIR=$(LIBDIR)-$(ARCH)

WHAT=	$(OBJDIR) $(OBJDIR)/start.o $(OBJDIR)/dyn_start.o $(OBJDIR)/dyn_stop.o \
	$(OBJDIR)/dietlibc.a $(OBJDIR)/liblatin1.a \
	$(OBJDIR)/libcompat.a $(OBJDIR)/libm.a \
	$(OBJDIR)/librpc.a $(OBJDIR)/libpthread.a \
	$(OBJDIR)/libcrypt.a \
	$(OBJDIR)/diet $(OBJDIR)/diet-i $(OBJDIR)/elftrunc \
	$(OBJDIR)/dnsd

all: $(WHAT)

profiling: $(OBJDIR)/libgmon.a $(OBJDIR)/pstart.o

CFLAGS=-pipe -nostdinc
CROSS=

CC=gcc
INC=-I. -isystem include

VPATH=lib:libstdio:libugly:libcruft:libcrypt:libshell:liblatin1:libcompat:libdl:librpc:libregex:libm:profiling

SYSCALLOBJ=$(patsubst syscalls.s/%.S,$(OBJDIR)/%.o,$(wildcard syscalls.s/*.S))

LIBOBJ=$(patsubst lib/%.c,$(OBJDIR)/%.o,$(wildcard lib/*.c))
LIBUGLYOBJ=$(patsubst libugly/%.c,$(OBJDIR)/%.o,$(wildcard libugly/*.c))
LIBSTDIOOBJ=$(patsubst libstdio/%.c,$(OBJDIR)/%.o,$(wildcard libstdio/*.c))
LIBCRUFTOBJ=$(patsubst libcruft/%.c,$(OBJDIR)/%.o,$(wildcard libcruft/*.c))
LIBCRYPTOBJ=$(patsubst libcrypt/%.c,$(OBJDIR)/%.o,$(wildcard libcrypt/*.c))
LIBSHELLOBJ=$(patsubst libshell/%.c,$(OBJDIR)/%.o,$(wildcard libshell/*.c))
LIBCOMPATOBJ=$(patsubst libcompat/%.c,$(OBJDIR)/%.o,$(wildcard libcompat/*.c)) $(OBJDIR)/syscall.o
LIBMATH=$(patsubst libm/%.c,%.o,$(wildcard libm/*.c))

LIBRPCOBJ=$(patsubst librpc/%.c,$(OBJDIR)/%.o,$(wildcard librpc/*.c))
LIBREGEXOBJ=$(patsubst libregex/%.c,$(OBJDIR)/%.o,$(wildcard libregex/*.c))

LIBDLOBJ=$(patsubst libdl/%.c,$(OBJDIR)/%.o,$(wildcard libdl/*.c)) $(OBJDIR)/_dl_jump.o

LIBPTHREAD_OBJS=$(patsubst libpthread/%.c,$(OBJDIR)/%.o,$(shell ./threadsafe.sh)) $(OBJDIR)/__testandset.o

LIBGMON_OBJS=$(OBJDIR)/__mcount.o $(OBJDIR)/monitor.o $(OBJDIR)/profil.o

include $(ARCH)/Makefile.add

LIBMATHOBJ=$(patsubst %,$(OBJDIR)/%,$(LIBMATH))

ifeq ($(CFLAGS),-pipe -nostdinc)
CFLAGS+=-O -fomit-frame-pointer
endif

ifneq ($(DEBUG),)
CFLAGS = -g
COMMENT = :
endif
CFLAGS += -W -Wall -Wextra -Wchar-subscripts -Wmissing-prototypes -Wmissing-declarations -Wno-switch -Wno-unused -Wredundant-decls

PWD=$(shell pwd)

.SUFFIXES:
.SUFFIXES: .S .c

# added real dynamic dietlibc.so
PICODIR = pic-$(ARCH)

$(OBJDIR) $(PICODIR):
	mkdir $@

% :: %,v

$(OBJDIR)/%.o: $(OBJDIR)

ifeq ($(CC),tcc)
$(OBJDIR)/%.o: %.S $(ARCH)/syscalls.h
	$(CROSS)cpp $(INC) $< | $(CROSS)as -o $@

$(OBJDIR)/%.o: %.c
	tcc -I. -Iinclude -c $< -o $@
	$(COMMENT) -$(CROSS)strip -x -R .comment -R .note $@
else
$(OBJDIR)/pstart.o: start.S
	$(CROSS)$(CC) $(INC) $(CFLAGS) -DPROFILING -c $< -o $@

$(OBJDIR)/%.o: %.S $(ARCH)/syscalls.h
	$(CROSS)$(CC) $(INC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/pthread_%.o: libpthread/pthread_%.c
	$(CROSS)$(CC) $(INC) $(CFLAGS) -c $< -o $@
	$(COMMENT) -$(CROSS)strip -x -R .comment -R .note $@

$(OBJDIR)/%.o: %.c
	$(CROSS)$(CC) $(INC) $(CFLAGS) -c $< -o $@ -D__dietlibc__
	$(COMMENT) -$(CROSS)strip -x -R .comment -R .note $@
endif

ifeq ($(shell $(CC) -v 2>&1 | grep "gcc version"),gcc version 4.0.0)
SAFE_CFLAGS=$(shell echo $(CFLAGS)|sed 's/-Os/-O2/')
SAFER_CFLAGS=$(shell echo $(CFLAGS)|sed 's/-Os/-O/')
else
SAFE_CFLAGS=$(CFLAGS)
SAFER_CFLAGS=$(CFLAGS)
endif

CC+=-D__dietlibc__

$(OBJDIR)/crypt.o: libcrypt/crypt.c
	$(CROSS)$(CC) $(INC) $(SAFER_CFLAGS) -c $< -o $@

DIETLIBC_OBJ = $(OBJDIR)/unified.o \
$(SYSCALLOBJ) $(LIBOBJ) $(LIBSTDIOOBJ) $(LIBUGLYOBJ) \
$(LIBCRUFTOBJ) $(LIBCRYPTOBJ) $(LIBSHELLOBJ) $(LIBREGEXOBJ) \
$(OBJDIR)/__longjmp.o $(OBJDIR)/setjmp.o \
$(OBJDIR)/clone.o

$(OBJDIR)/dietlibc.a: $(DIETLIBC_OBJ) $(OBJDIR)/start.o
	$(CROSS)ar cru $@ $(DIETLIBC_OBJ)

$(OBJDIR)/librpc.a: $(LIBRPCOBJ)
	$(CROSS)ar cru $@ $(LIBRPCOBJ)

$(OBJDIR)/libcrypt.a:
	touch dummy.c
	$(CROSS)$(CC) -c dummy.c
	$(CROSS)ar cru $@ dummy.o
	rm -f dummy.c dummy.o

dummy.o:

LIBLATIN1_OBJS=$(patsubst liblatin1/%.c,$(OBJDIR)/%.o,$(wildcard liblatin1/*.c))
$(OBJDIR)/liblatin1.a: $(LIBLATIN1_OBJS)
	$(CROSS)ar cru $@ $^

$(OBJDIR)/libgmon.a: $(LIBGMON_OBJS)
	$(CROSS)ar cru $@ $^

$(OBJDIR)/libpthread.a: $(LIBPTHREAD_OBJS) dietfeatures.h
	$(CROSS)ar cru $@ $(LIBPTHREAD_OBJS)

$(OBJDIR)/libcompat.a: $(LIBCOMPATOBJ)
	$(CROSS)ar cru $@ $(LIBCOMPATOBJ)

$(OBJDIR)/libm.a: $(LIBMATHOBJ)
	$(CROSS)ar cru $@ $(LIBMATHOBJ)

LD_UNSET = env -u LD_RUN_PATH

dyn: dyn_lib

# added dynamic linker
$(OBJDIR)/libdl.a: $(LIBDLOBJ)
	$(CROSS)ar cru $@ $(LIBDLOBJ)

dyn_lib: $(PICODIR) $(PICODIR)/libc.so $(PICODIR)/dstart.o \
	$(PICODIR)/dyn_so_start.o $(PICODIR)/dyn_start.o $(PICODIR)/dyn_stop.o \
	$(PICODIR)/libpthread.so $(PICODIR)/libdl.so $(PICODIR)/libcompat.so \
	$(PICODIR)/libm.so $(PICODIR)/diet-dyn $(PICODIR)/diet-dyn-i

$(PICODIR)/%.o: %.S $(ARCH)/syscalls.h
	$(CROSS)$(CC) $(INC) $(CFLAGS) -fPIC -D__DYN_LIB -c $< -o $@

$(PICODIR)/pthread_%.o: libpthread/pthread_%.c
	$(CROSS)$(CC) $(INC) $(CFLAGS) -fPIC -D__DYN_LIB -c $< -o $@
	$(COMMENT) $(CROSS)strip -x -R .comment -R .note $@

$(PICODIR)/%.o: %.c
	$(CROSS)$(CC) $(INC) $(CFLAGS) -fPIC -D__DYN_LIB -c $< -o $@
	$(COMMENT) $(CROSS)strip -x -R .comment -R .note $@

$(PICODIR)/dstart.o: start.S
	$(CROSS)$(CC) $(INC) $(CFLAGS) -fPIC -D__DYN_LIB -c $< -o $@

$(PICODIR)/dyn_so_start.o: dyn_start.c
	$(CROSS)$(CC) $(INC) $(CFLAGS) -fPIC -D__DYN_LIB -D__DYN_LIB_SHARED -c $< -o $@
	$(COMMENT) $(CROSS)strip -x -R .comment -R .note $@

DYN_LIBC_PIC = $(LIBOBJ) $(LIBSTDIOOBJ) $(LIBUGLYOBJ) \
$(LIBCRUFTOBJ) $(LIBCRYPTOBJ) $(LIBSHELLOBJ) $(LIBREGEXOBJ)

DYN_LIBC_OBJ = $(PICODIR)/dyn_syscalls.o $(PICODIR)/errlist.o \
	$(patsubst $(OBJDIR)/%.o,$(PICODIR)/%.o,$(DYN_LIBC_PIC))

DYN_PTHREAD_OBJS = $(patsubst $(OBJDIR)/%.o,$(PICODIR)/%.o,$(LIBPTHREAD_OBJS))

DYN_LIBDL_OBJS = $(patsubst $(OBJDIR)/%.o,$(PICODIR)/%.o,$(LIBDLOBJ))

DYN_LIBCOMPAT_OBJS = $(patsubst $(OBJDIR)/%.o,$(PICODIR)/%.o,$(LIBCOMPATOBJ))

DYN_LIBMATH_OBJS = $(patsubst $(OBJDIR)/%.o,$(PICODIR)/%.o,$(LIBMATHOBJ))

$(PICODIR)/libc.so: $(PICODIR) $(DYN_LIBC_OBJ)
	$(LD_UNSET) $(CROSS)$(CC) -nostdlib -shared -o $@ $(CFLAGS) -fPIC $(DYN_LIBC_OBJ) -lgcc -Wl,-soname=libc.so

$(PICODIR)/libpthread.so: $(DYN_PTHREAD_OBJS) dietfeatures.h
	$(LD_UNSET) $(CROSS)$(CC) -nostdlib -shared -o $@ $(CFLAGS) -fPIC $(DYN_PTHREAD_OBJS) -L$(PICODIR) -lc -Wl,-soname=libpthread.so

$(PICODIR)/libdl.so: libdl/_dl_main.c dietfeatures.h
	$(LD_UNSET) $(CROSS)$(CC) -D__OD_CLEAN_ROOM -DNODIETREF -fPIC -nostdlib -shared -Bsymbolic -Wl,-Bsymbolic \
		-o $@ $(SAFE_CFLAGS) $(INC) libdl/_dl_main.c -Wl,-soname=libdl.so

$(OBJDIR)/pthread_create.o $(PICODIR)/pthread_create.o: dietfeatures.h
$(OBJDIR)/pthread_internal.o $(PICODIR)/pthread_internal.o: dietfeatures.h

#$(PICODIR)/libdl.so: $(DYN_LIBDL_OBJS) dietfeatures.h
#	$(CROSS)$(CC) -nostdlib -shared -o $@ $(CFLAGS) -fPIC $(DYN_LIBDL_OBJS) -L$(PICODIR) -ldietc -Wl,-soname=libdl.so

$(PICODIR)/libcompat.so: $(DYN_LIBCOMPAT_OBJS) dietfeatures.h
	$(LD_UNSET) $(CROSS)$(CC) -nostdlib -shared -o $@ $(CFLAGS) -fPIC $(DYN_LIBCOMPAT_OBJS) -L$(PICODIR) -lc -Wl,-soname=libcompat.so

$(PICODIR)/libm.so: $(DYN_LIBMATH_OBJS) dietfeatures.h
	$(LD_UNSET) $(CROSS)$(CC) -nostdlib -shared -o $@ $(CFLAGS) -fPIC $(DYN_LIBMATH_OBJS) -L$(PICODIR) -lc -Wl,-soname=libm.so


$(SYSCALLOBJ): syscalls.h

$(OBJDIR)/elftrunc: $(OBJDIR)/diet contrib/elftrunc.c
	bin-$(MYARCH)/diet $(CROSS)$(CC) $(CFLAGS) -o $@ contrib/elftrunc.c

$(OBJDIR)/dnsd: $(OBJDIR)/diet contrib/dnsd.c
	bin-$(MYARCH)/diet $(CROSS)$(CC) $(CFLAGS) -o $@ contrib/dnsd.c

VERSION=dietlibc-$(shell head -n 1 CHANGES|sed 's/://')
CURNAME=$(notdir $(shell pwd))

$(OBJDIR)/diet: $(OBJDIR)/start.o $(OBJDIR)/dyn_start.o diet.c $(OBJDIR)/dietlibc.a $(OBJDIR)/dyn_stop.o
	$(CROSS)$(CC) -isystem include $(CFLAGS) -nostdlib -o $@ $^ -DDIETHOME=\"$(HOME)\" -DVERSION=\"$(VERSION)\" -lgcc
	$(CROSS)strip -R .comment -R .note $@

$(OBJDIR)/diet-i: $(OBJDIR)/start.o $(OBJDIR)/dyn_start.o diet.c $(OBJDIR)/dietlibc.a $(OBJDIR)/dyn_stop.o
	$(CROSS)$(CC) -isystem include $(CFLAGS) -nostdlib -o $@ $^ -DDIETHOME=\"$(prefix)\" -DVERSION=\"$(VERSION)\" -DINSTALLVERSION -lgcc
	$(CROSS)strip -R .comment -R .note $@

$(PICODIR)/diet-dyn: $(PICODIR)/start.o $(PICODIR)/dyn_start.o diet.c
	$(LD_UNSET) $(CROSS)$(CC) -isystem include $(CFLAGS) -fPIC -nostdlib -o $@ $^ -DDIETHOME=\"$(HOME)\" -D__DYN_LIB -DVERSION=\"$(VERSION)\" -L$(PICODIR) -lc -lgcc $(PICODIR)/dyn_stop.o -Wl,-dynamic-linker=$(HOME)/$(PICODIR)/libdl.so
	$(CROSS)strip -R .command -R .note $@

$(PICODIR)/diet-dyn-i: $(PICODIR)/start.o $(PICODIR)/dyn_start.o diet.c
	$(LD_UNSET) $(CROSS)$(CC) -isystem include $(CFLAGS) -fPIC -nostdlib -o $@ $^ -DDIETHOME=\"$(prefix)\" -D__DYN_LIB -DVERSION=\"$(VERSION)\" -L$(PICODIR) -lc -lgcc $(PICODIR)/dyn_stop.o -Wl,-dynamic-linker=$(ILIBDIR)/libdl.so -DINSTALLVERSION
	$(CROSS)strip -R .command -R .note $@

$(OBJDIR)/djb: $(OBJDIR)/compile $(OBJDIR)/load

$(OBJDIR)/compile:
	echo 'exec' $(CC) '$(CFLAGS) -I$(PWD)/$(OBJDIR)/include -c $${1+"$$@"}' > $@
	chmod 755 $@

$(OBJDIR)/load:
	echo 'main="$$1"; shift; exec' $(CC) '-nostdlib -o "$$main" $(PWD)/$(OBJDIR)/start.o "$$main".o $${1+"$$@"} $(PWD)/$(OBJDIR)/dietlibc.a -lgcc'  > $@
	chmod 755 $@

clean:
	rm -f *.o *.a t t1 compile load elftrunc exports mapfile libdietc.so
	rm -rf bin-* pic-*
	$(MAKE) -C examples clean
	$(MAKE) -C dynlinker clean
	$(MAKE) -C libdl clean

tar: clean rename
	cd ..; tar cvvf $(VERSION).tar.bz2 --use=bzip2 --exclude CVS $(VERSION)

rename:
	if test $(CURNAME) != $(VERSION); then cd .. && mv $(CURNAME) $(VERSION); fi

$(OBJDIR)/exports: $(OBJDIR)/dietlibc.a
	nm -g $(OBJDIR)/dietlibc.a | grep '\<T\>' | awk '{ print $$3 }' | sort -u > $(OBJDIR)/exports

.PHONY: t t1
t:
	$(CROSS)$(CC) -g $(CFLAGS) -fno-builtin -nostdlib -isystem include -o t t.c $(OBJDIR)/start.o $(OBJDIR)/dyn_start.o $(OBJDIR)/dietlibc.a -lgcc $(OBJDIR)/dyn_stop.o -Wl,-Map,mapfile

t1:
	$(CROSS)$(CC) -g -o t1 t.c

install-bin: $(OBJDIR)/start.o $(OBJDIR)/dietlibc.a $(OBJDIR)/librpc.a $(OBJDIR)/liblatin1.a $(OBJDIR)/libcompat.a $(OBJDIR)/elftrunc $(OBJDIR)/diet-i
	$(INSTALL) -d $(DESTDIR)$(ILIBDIR) $(DESTDIR)$(MAN1DIR) $(DESTDIR)$(BINDIR)
	$(INSTALL) $(OBJDIR)/start.o $(DESTDIR)$(ILIBDIR)/start.o
	$(INSTALL) -m 644 $(OBJDIR)/libm.a $(OBJDIR)/libpthread.a $(OBJDIR)/librpc.a \
$(OBJDIR)/liblatin1.a $(OBJDIR)/libcompat.a $(OBJDIR)/libcrypt.a $(DESTDIR)$(ILIBDIR)
	$(INSTALL) -m 644 $(OBJDIR)/dietlibc.a $(DESTDIR)$(ILIBDIR)/libc.a
ifeq ($(MYARCH),$(ARCH))
	$(INSTALL) $(OBJDIR)/diet-i $(DESTDIR)$(BINDIR)/diet
	-$(INSTALL) $(PICODIR)/diet-dyn-i $(DESTDIR)$(BINDIR)/diet-dyn
endif
	$(INSTALL) -m 755 $(OBJDIR)/elftrunc $(OBJDIR)/dnsd $(DESTDIR)$(BINDIR)
	$(INSTALL) -m 644 diet.1 $(DESTDIR)$(MAN1DIR)/diet.1

install-profiling:
	-$(INSTALL) $(OBJDIR)/pstart.o $(OBJDIR)/libgmon.a $(OBJDIR)/dyn_start.o $(OBJDIR)/dyn_stop.o $(DESTDIR)$(ILIBDIR)

install-pic:
	-$(INSTALL) $(PICODIR)/libc.so $(DESTDIR)$(ILIBDIR)/libc.so
	-$(INSTALL) $(PICODIR)/libpthread.so $(DESTDIR)$(ILIBDIR)/libpthread.so
	-$(INSTALL) $(PICODIR)/libdl.so $(DESTDIR)$(ILIBDIR)/libdl.so
	-$(INSTALL) $(PICODIR)/libcompat.so $(DESTDIR)$(ILIBDIR)/libcompat.so
	-$(INSTALL) $(PICODIR)/libm.so $(DESTDIR)$(ILIBDIR)/libm.so
	-$(INSTALL) $(PICODIR)/dyn_start.o $(DESTDIR)$(ILIBDIR)/dyn_dstart.o
	-$(INSTALL) $(PICODIR)/dyn_stop.o  $(DESTDIR)$(ILIBDIR)/dyn_dstop.o
	-$(INSTALL) $(PICODIR)/dstart.o $(PICODIR)/dyn_so_start.o $(DESTDIR)$(ILIBDIR)
	if test -f $(PICODIR)/libc.so -a ! -f $(DESTDIR)/etc/diet.ld.conf; then echo "$(ILIBDIR)" > $(DESTDIR)/etc/diet.ld.conf; fi

install-headers:
	for i in `find include -name \*.h`; do install -m 644 -D $$i $(DESTDIR)$(prefix)/$$i; done


install: install-bin install-profiling install-pic install-headers

uninstall:
	for i in start.o libm.a libpthread.a librpc.a liblatin1.a libcompat.a libcrypt.a libc.a; do rm -f $(DESTDIR)$(ILIBDIR)/$$i; done
	rm -f $(DESTDIR)$(BINDIR)/diet $(DESTDIR)$(BINDIR)/diet-dyn
	for i in libgmon.a dyn_start.o dyn_stop.o libc.so libpthread.so libdl.so libcompat.so dyn_dstart.o dyn_dstop.o dyn_so_start.o; do rm -f $(DESTDIR)$(ILIBDIR)/$$i; done
	rm -f $(DESTDIR)$(MAN1DIR)/diet.1 $(DESTDIR)/etc/diet.ld.conf
	for i in `find include -name \*.h`; do rm -f $(DESTDIR)$(prefix)/$$i; done
	-rmdir $(DESTDIR)$(ILIBDIR) $(DESTDIR)$(MAN1DIR) $(DESTDIR)$(BINDIR)

.PHONY: sparc ppc mips arm alpha i386 parisc mipsel powerpc s390 sparc64
.PHONY: x86_64 ia64 ppc64 s390x

arm sparc alpha mips parisc s390 sparc64 x86_64 ia64 ppc64 s390x:
	$(MAKE) ARCH=$@ CROSS=$@-linux- all

i386:
ifeq ($(MYARCH),x86_64)
	$(MAKE) ARCH=$@ CC="$(CC) -m32" all
else
	$(MAKE) ARCH=$@ CROSS=$@-linux- all
endif

ppc:
ifeq ($(MYARCH),ppc64)
	$(MAKE) ARCH=$@ CC="$(CC) -m32" all
else
	$(MAKE) ARCH=$@ CROSS=$@-linux- all
endif

# Cross compile for little endian MIPS
mipsel:
	$(MAKE) ARCH=$@ CROSS=mips-linux- all

mips-gnu:
	$(MAKE) ARCH=$@ CROSS=$@-linux-gnu- all

# Some people named their cross compiler toolchain powerpc-linux-gcc
powerpc:
	$(MAKE) ARCH=ppc CROSS=powerpc-linux- all

hppa:
	ln -sf bin-parisc bin-hppa
	$(MAKE) ARCH=parisc CROSS=hppa-linux- all

CROSS_ARCH=arm sparc ppc alpha i386 mips sparc64 x86_64 s390 parisc
cross:
	$(MAKE) $(subst $(ARCH),,$(CROSS_ARCH))


# these depend on dietfeatures.h for large file backward compatibility
$(OBJDIR)/__fstat64.o $(OBJDIR)/__lstat64.o $(OBJDIR)/__stat64.o $(OBJDIR)/lseek64.o $(OBJDIR)/readdir64.o $(OBJDIR)/stat64.o $(OBJDIR)/lstat64.o $(OBJDIR)/fstat64.o $(OBJDIR)/truncate64.o $(OBJDIR)/__truncate64.o $(OBJDIR)/ftruncate64.o $(OBJDIR)/__ftruncate64.o $(OBJDIR)/sendfile64.o $(OBJDIR)/__sendfile64.o $(PICODIR)/dyn_syscalls.o $(PICODIR)/__truncate64.o $(PICODIR)/__ftruncate64.o $(PICODIR)/__stat64.o $(PICODIR)/__lstat64.o $(PICODIR)/__fstat64.o $(OBJDIR)/__sendfile64.o $(OBJDIR)/fstatfs64.o $(OBJDIR)/statfs64.o: dietfeatures.h

# these depend on dietfeatures.h for thread support
$(OBJDIR)/alloc.o $(OBJDIR)/perror.o $(OBJDIR)/logging.o $(OBJDIR)/unified.o $(OBJDIR)/clone.o $(OBJDIR)/set_errno.o: dietfeatures.h

# these depend on dietfeatures.h for linker warnings
$(OBJDIR)/assert_fail.o $(OBJDIR)/sprintf.o $(OBJDIR)/vsnprintf.o $(OBJDIR)/___div.o $(OBJDIR)/fflush.o $(OBJDIR)/setvbuf.o $(OBJDIR)/system.o $(OBJDIR)/sendfile.o $(OBJDIR)/setenv.o: dietfeatures.h

# these depend on dietfeatures.h for buffered stdio
fclose.o $(OBJDIR)/fdglue.o $(OBJDIR)/fflush.o $(OBJDIR)/fgetc.o $(OBJDIR)/fputc.o $(OBJDIR)/fread.o $(OBJDIR)/fseek.o $(OBJDIR)/printf.o $(OBJDIR)/setvbuf.o $(OBJDIR)/stderr.o $(OBJDIR)/stdin.o $(OBJDIR)/stdout.o $(OBJDIR)/fwrite.o $(OBJDIR)/puts.o: dietfeatures.h

# these depend on dietfeatures.h for fast string routines
strcasecmp.o $(OBJDIR)/strcat.o $(OBJDIR)/strchr.o $(OBJDIR)/strcmp.o $(OBJDIR)/strcpy.o $(OBJDIR)/strlen.o $(OBJDIR)/strncasecmp.o $(OBJDIR)/strncat.o $(OBJDIR)/strrchr.o: dietfeatures.h

# this depends on dietfeatures.h for WANT_NON_COMPLIANT_STRNCAT
$(OBJDIR)/strncpy.o: dietfeatures.h

# these depend on dietfeatures.h for /proc
$(OBJDIR)/ttyname.o $(OBJDIR)/sysconf_cpus.o: dietfeatures.h

# these depend on dietfeatures.h for WANT_TZFILE_PARSER
$(OBJDIR)/localtime_r.o $(OBJDIR)/strftime.o $(OBJDIR)/tzfile.o: dietfeatures.h

# these depend on dietfeatures.h for WANT_SMALL_STDIO_BUFS
$(LIBSTDIOOBJ): dietfeatures.h include/stdio.h dietstdio.h

# these depend on dietfeatures.h for WANT_FULL_RESOLV_CONF
$(OBJDIR)/dnscruft.o $(OBJDIR)/dnscruft2.o $(OBJDIR)/res_search.o $(OBJDIR)/res_query.o: dietfeatures.h

# these depend on dietfeatures.h for WANT_THREAD_SAFE and errno
$(LIBRPCOBJ) $(OBJDIR)/logging.o $(OBJDIR)/alloc.o $(OBJDIR)/cfsetospeed.o $(OBJDIR)/cfsetispeed.o \
$(OBJDIR)/execl.o $(OBJDIR)/execlp.o $(OBJDIR)/execv.o $(OBJDIR)/execvp.o $(OBJDIR)/isatty.o \
$(OBJDIR)/lockf.o $(OBJDIR)/perror.o $(OBJDIR)/remove.o $(OBJDIR)/set_errno.o $(OBJDIR)/sigemptyset.o \
$(OBJDIR)/tcsetattr.o $(OBJDIR)/dnscruft2.o $(OBJDIR)/dnscruft.o $(OBJDIR)/entlib.o \
$(OBJDIR)/gethostbyaddr.o $(OBJDIR)/gethostbyaddr_r.o $(OBJDIR)/gethostbyname.o \
$(OBJDIR)/gethostbyname_r.o $(OBJDIR)/gethostbyname2.o $(OBJDIR)/gethostbyname2_r.o \
$(OBJDIR)/inet_pton.o $(OBJDIR)/mkstemp.o $(OBJDIR)/mktemp.o $(OBJDIR)/tempnam.o \
$(OBJDIR)/glob.o $(OBJDIR)/realpath.o $(OBJDIR)/fdglue.o $(OBJDIR)/fdglue2.o \
$(OBJDIR)/getaddrinfo.o $(OBJDIR)/getnameinfo.o $(OBJDIR)/getprotoent.o \
$(OBJDIR)/getservent.o $(OBJDIR)/iconv.o $(OBJDIR)/iconv_open.o \
$(OBJDIR)/netent.o $(OBJDIR)/system.o $(OBJDIR)/stdin.o $(OBJDIR)/stdout.o \
$(OBJDIR)/stderr.o: dietfeatures.h

# these depend on dietfeatures.h for WANT_CRYPT_MD5
$(OBJDIR)/crypt.o: dietfeatures.h

# these depend on dietfeatures.h for WANT_FREAD_OPTIMIZATION
$(OBJDIR)/fread.o $(OBJDIR)/fwrite.o: dietfeatures.h

# these depend on dietfeatures.h for WANT_DYNAMIC
$(OBJDIR)/start.o $(OBJDIR)/dyn_start.o $(OBJDIR)/dyn_stop.o: dietfeatures.h

$(OBJDIR)/unified.o: dietuglyweaks.h

$(OBJDIR)/adjtimex.o: include/sys/timex.h

$(OBJDIR)/fgetc_unlocked.o $(OBJDIR)/fread.o $(OBJDIR)/ungetc.o: dietstdio.h

# these depend on dietfeatures.h for WANT_LINKER_WARNINGS
$(OBJDIR)/setlinebuf.o $(OBJDIR)/bzero.o $(OBJDIR)/setegid.o \
$(OBJDIR)/seteuid.o $(OBJDIR)/toascii.o: dietfeatures.h

# these depend on dietfeatures.h for WANT_FULL_POSIX_COMPAT
$(OBJDIR)/strncpy.o: dietfeatures.h
$(OBJDIR)/strxfrm.o: dietfeatures.h

$(OBJDIR)/stat.o $(OBJDIR)/fstat.o $(OBJDIR)/lstat.o: include/sys/stat.h
$(OBJDIR)/stat64.o $(OBJDIR)/fstat64.o $(OBJDIR)/lstat64.o: include/sys/stat.h

# these depend on dietfeatures.h for WANT_INET_ADDR_DNS
$(OBJDIR)/gethostbyname_r.o: dietfeatures.h

# WANT_PLUGPLAY_DNS
$(OBJDIR)/getaddrinfo.o: dietfeatures.h

$(OBJDIR)/strsignal.o: include/signal.h

$(LIBPTHREAD_OBJS): include/pthread.h

# CFLAGS+=-W -Wshadow -Wid-clash-31 -Wpointer-arith -Wcast-align -Wstrict-prototypes -Wwrite-strings

# WANT_LARGEFILE_BACKCOMPAT
$(OBJDIR)/fcntl64.o: dietfeatures.h

# WANT_SSP
# This facepalm brought to you by: Ubuntu!
$(OBJDIR)/stackgap.o: dietfeatures.h
	$(CROSS)$(CC) $(INC) $(CFLAGS) -c lib/stackgap.c -o $@ -D__dietlibc__ -fno-stack-protector
	$(COMMENT) -$(CROSS)strip -x -R .comment -R .note $@

# WANT_MALLOC_ZERO
$(OBJDIR)/strndup.o: dietfeatures.h

ARCH=x86_64

OBJDIR=bin-$(ARCH)
ILIBDIR=$(LIBDIR)-$(ARCH)

WHATBASE= dietlibc.a liblatin1.a libcompat.a libm.a libcrypt.a
WHAT= $(WHATBASE:%=$(OBJDIR)/%)

all: $(OBJDIR) $(WHAT)

$(OBJDIR):
	mkdir $@

CROSS=

CC=gcc
INC=-I. -isystem include

VPATH=lib:libstdio:libugly:libcruft:liblatin1:libcompat:libm:libregex

LIBOBJ=$(patsubst lib/%.c,$(OBJDIR)/%.o,$(wildcard lib/*.c))
LIBUGLYOBJ=$(patsubst libugly/%.c,$(OBJDIR)/%.o,$(wildcard libugly/*.c))
LIBSTDIOOBJ=$(patsubst libstdio/%.c,$(OBJDIR)/%.o,$(wildcard libstdio/*.c))
#LIBCRUFTOBJ=$(patsubst libcruft/%.c,$(OBJDIR)/%.o,$(wildcard libcruft/*.c))
LIBCRYPTOBJ=$(patsubst libcrypt/%.c,$(OBJDIR)/%.o,$(wildcard libcrypt/*.c))
LIBSHELLOBJ=$(patsubst libshell/%.c,$(OBJDIR)/%.o,$(wildcard libshell/*.c))
LIBCOMPATOBJ=$(patsubst libcompat/%.c,$(OBJDIR)/%.o,$(wildcard libcompat/*.c)) $(OBJDIR)/syscall.o
LIBMATH=$(patsubst libm/%.c,%.o,$(wildcard libm/*.c))

LIBRPCOBJ=$(patsubst librpc/%.c,$(OBJDIR)/%.o,$(wildcard librpc/*.c))
LIBREGEXOBJ=$(patsubst libregex/%.c,$(OBJDIR)/%.o,$(wildcard libregex/*.c))

LIBGMON_OBJS=$(OBJDIR)/__mcount.o $(OBJDIR)/monitor.o $(OBJDIR)/profil.o

include $(ARCH)/Makefile.add

LIBMATHOBJ=$(patsubst %,$(OBJDIR)/%,$(LIBMATH))

ifneq ($(DEBUG),)
CFLAGS += -g
COMMENT = :
endif
CFLAGS += -pipe -nostdinc -std=gnu99 -m64 -mno-red-zone -fno-reorder-blocks
CFLAGS += -W -Wall -Wextra -Wchar-subscripts -Wmissing-prototypes -Wmissing-declarations -Wno-switch -Wno-unused -Wredundant-decls

PWD=$(shell pwd)

.SUFFIXES:
.SUFFIXES: .S .c

% :: %,v

$(OBJDIR)/%.o: %.S $(ARCH)/syscalls.h
	$(CROSS)$(CC) $(INC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: %.c
	$(CROSS)$(CC) $(INC) $(CFLAGS) -c $< -o $@ -D__dietlibc__
	$(COMMENT) -$(CROSS)strip -x -R .comment -R .note $@

SAFE_CFLAGS=$(CFLAGS)
SAFER_CFLAGS=$(CFLAGS)

CC+=-D__dietlibc__

$(OBJDIR)/crypt.o: libcrypt/crypt.c
	$(CROSS)$(CC) $(INC) $(SAFER_CFLAGS) -c $< -o $@

DIETLIBC_OBJ = $(LIBOBJ) $(LIBSTDIOOBJ) $(LIBUGLYOBJ) \
	 $(LIBREGEXOBJ) \
$(OBJDIR)/__longjmp.o $(OBJDIR)/setjmp.o \
$(OBJDIR)/clone.o

$(OBJDIR)/dietlibc.a: $(DIETLIBC_OBJ)
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

$(SYSCALLOBJ): syscalls.h

clean:
	rm -f *.o *.a t
	rm -rf bin-* pic-*

prefix ?= ../inst-x86_64

install-headers:
	for i in `find include -name \*.h`; do install -m 644 -D $$i $(prefix)/$$i; done

install-libs:
	for i in $(WHATBASE); do install -m 644 -D $(OBJDIR)/$$i $(prefix)/lib/$$i; done
	mv $(prefix)/lib/dietlibc.a $(prefix)/lib/libc.a

install: install-headers install-libs

.PHONY: x86_64 

x86_64:
	$(MAKE) ARCH=$@ CROSS=$@-linux- all

# these depend on dietfeatures.h for large file backward compatibility
$(OBJDIR)/__fstat64.o $(OBJDIR)/__lstat64.o $(OBJDIR)/__stat64.o $(OBJDIR)/lseek64.o $(OBJDIR)/readdir64.o $(OBJDIR)/stat64.o $(OBJDIR)/lstat64.o $(OBJDIR)/fstat64.o $(OBJDIR)/truncate64.o $(OBJDIR)/__truncate64.o $(OBJDIR)/ftruncate64.o $(OBJDIR)/__ftruncate64.o $(OBJDIR)/sendfile64.o $(OBJDIR)/__sendfile64.o $(OBJDIR)/__sendfile64.o $(OBJDIR)/fstatfs64.o $(OBJDIR)/statfs64.o: dietfeatures.h

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

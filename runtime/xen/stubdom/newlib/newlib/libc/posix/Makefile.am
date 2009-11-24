## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = \
	closedir.c creat.c isatty.c \
	opendir.c readdir.c \
	readdir_r.c rewinddir.c sleep.c usleep.c \
	telldir.c

ELIX_2_SOURCES = \
        scandir.c seekdir.c

ELIX_3_SOURCES = \
	execl.c execle.c execlp.c execv.c \
	execve.c execvp.c

ELIX_4_SOURCES = \
	popen.c 

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

libposix_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libposix.la
libposix_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared	

CHEWOUT_FILES =

SUFFIXES = .def

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

# No doc for posix.
doc:

CLEANFILES = $(CHEWOUT_FILES) *.ref

## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

if HAVE_STDIO64_DIR
STDIO64_SOURCES = \
	fstat64r.c \
	lseek64r.c \
	open64r.c

STDIO64_DEFS = \
	fstat64r.def \
	lseek64r.def \
	open64r.def
endif

ELIX_2_SOURCES = $(STDIO64_SOURCES)
ELIX_3_SOURCES = execr.c

if ELIX_LEVEL_1
ELIX_SOURCES =
else
if ELIX_LEVEL_2
ELIX_SOURCES = $(ELIX_2_SOURCES)
else
ELIX_SOURCES = $(ELIX_2_SOURCES) $(ELIX_3_SOURCES)
endif
endif

GENERAL_SOURCES = \
	closer.c \
	reent.c \
	impure.c \
	fcntlr.c \
	fstatr.c \
	getreent.c \
	gettimeofdayr.c \
	linkr.c \
	lseekr.c \
	openr.c \
	readr.c \
	renamer.c \
	signalr.c \
	signgam.c \
	sbrkr.c \
	statr.c \
	timesr.c \
	unlinkr.c \
	writer.c

libreent_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libreent.la
libreent_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared

CHEWOUT_FILES = \
	closer.def \
	reent.def \
	execr.def \
	fcntlr.def \
	fstatr.def \
	gettimeofdayr.def \
	linkr.def \
	lseekr.def \
	openr.def \
	readr.def \
	renamer.def \
	signalr.def \
	sbrkr.def \
	statr.def \
	timesr.def \
	unlinkr.def \
	$(STDIO64_DEFS) \
	writer.def

SUFFIXES = .def .h

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/reent.tex >> $(TARGETDOC)

$(lpfx)impure.$(oext): $(srcdir)/impure.c $(srcdir)/../include/sys/reent.h

CLEANFILES = $(CHEWOUT_FILES) *.ref

## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = 	\
	ctype_.c 	\
	isalnum.c 	\
	isalpha.c 	\
	iscntrl.c 	\
	isdigit.c 	\
	islower.c 	\
	isupper.c 	\
	isprint.c 	\
	ispunct.c 	\
	isspace.c 	\
	isxdigit.c 	\
	tolower.c 	\
	toupper.c

## The following handles EL/IX level 2 functions
if ELIX_LEVEL_1
ELIX_SOURCES =
else
ELIX_SOURCES = \
	isascii.c 	\
	isblank.c 	\
	iswalnum.c 	\
	iswalpha.c 	\
	iswblank.c 	\
	iswcntrl.c 	\
	iswctype.c 	\
	iswdigit.c 	\
	iswgraph.c 	\
	iswlower.c 	\
	iswprint.c 	\
	iswpunct.c 	\
	iswspace.c 	\
	iswupper.c 	\
	iswxdigit.c 	\
	jp2uc.c 	\
	toascii.c 	\
	_tolower.c 	\
	_toupper.c 	\
	towctrans.c 	\
	towlower.c 	\
	towupper.c 	\
	wctrans.c 	\
	wctype.c
endif

libctype_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libctype.la
libctype_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared

CHEWOUT_FILES= \
	isalnum.def	\
	isalpha.def	\
	isascii.def	\
	iscntrl.def	\
	isdigit.def	\
	islower.def	\
	isprint.def	\
	ispunct.def	\
	isspace.def	\
	isupper.def	\
	iswalnum.def	\
	iswalpha.def	\
	iswblank.def 	\
	iswcntrl.def 	\
	iswctype.def 	\
	iswdigit.def 	\
	iswgraph.def 	\
	iswlower.def 	\
	iswprint.def 	\
	iswpunct.def 	\
	iswspace.def 	\
	iswupper.def 	\
	iswxdigit.def 	\
	isxdigit.def	\
	toascii.def	\
	tolower.def	\
	toupper.def	\
	towctrans.def	\
	towlower.def	\
	towupper.def	\
	wctrans.def	\
	wctype.def	

SUFFIXES = .def

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/ctype.tex >> $(TARGETDOC)

CLEANFILES = $(CHEWOUT_FILES) *.ref

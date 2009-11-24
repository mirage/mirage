## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = \
	bcopy.c \
	bzero.c \
	index.c \
	memchr.c \
	memcmp.c \
	memcpy.c \
	memmove.c \
	memset.c \
	rindex.c \
	strcasecmp.c \
	strcat.c \
	strchr.c \
	strcmp.c \
	strcoll.c \
	strcpy.c \
	strcspn.c \
	strdup.c \
	strdup_r.c \
	strerror.c \
	strerror_r.c \
	strlcat.c \
	strlcpy.c \
	strlen.c  \
	strlwr.c \
	strncasecmp.c \
	strncat.c \
	strncmp.c \
	strncpy.c \
	strnlen.c \
	strpbrk.c \
	strrchr.c \
	strsep.c \
	strspn.c \
	strtok.c \
	strtok_r.c \
	strupr.c \
	strxfrm.c  \
	strstr.c \
	swab.c \
	u_strerr.c \
	wcscat.c \
	wcschr.c \
	wcscmp.c \
	wcscoll.c \
	wcscpy.c \
	wcscspn.c \
	wcslcat.c \
	wcslcpy.c \
	wcslen.c \
	wcsncat.c \
	wcsncmp.c \
	wcsncpy.c \
	wcsnlen.c \
	wcspbrk.c \
	wcsrchr.c \
	wcsspn.c \
	wcsstr.c \
	wcswidth.c \
	wcsxfrm.c \
	wcwidth.c \
	wmemchr.c \
	wmemcmp.c \
	wmemcpy.c \
	wmemmove.c \
	wmemset.c

if ELIX_LEVEL_1
ELIX_SOURCES =
else
ELIX_SOURCES = \
	bcmp.c \
	memccpy.c \
	mempcpy.c \
	stpcpy.c \
	stpncpy.c \
	strndup.c \
	strcasestr.c \
	strndup_r.c \
	wcpcpy.c \
	wcpncpy.c \
endif

libstring_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libstring.la
libstring_la_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared

CHEWOUT_FILES=\
bcmp.def	memcpy.def	strcmp.def	strncat.def strstr.def \
bcopy.def	memmove.def	strcoll.def	strncmp.def strtok.def \
bzero.def	memset.def	strcpy.def	strncpy.def strxfrm.def \
index.def	rindex.def	strcspn.def	strpbrk.def swab.def \
memchr.def	strcat.def	strerror.def	strerror_r.def strrchr.def \
memcmp.def	strchr.def	strlen.def	strnlen.def strspn.def \
strcasecmp.def	strncasecmp.def strcasestr.def	strlwr.def  strupr.def \
memccpy.def 	mempcpy.def	stpcpy.def	stpncpy.def \
wcscat.def	wcschr.def	wcscmp.def	wcscoll.def \
wcscpy.def	wcscspn.def	wcpcpy.def	wcpncpy.def \
wcslcat.def	wcslcpy.def	wcslen.def	wcsncat.def \
wcsncmp.def	wcsncpy.def	wcsnlen.def	wcspbrk.def \
wcsrchr.def	wcsspn.def	wcsstr.def \
wcswidth.def	wcsxfrm.def	wcwidth.def	wmemchr.def \
wmemcmp.def	wmemcpy.def	wmemmove.def	wmemset.def

SUFFIXES = .def

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/strings.tex >> $(TARGETDOC)
	cat $(srcdir)/wcstrings.tex >> $(TARGETDOC)

CLEANFILES = $(CHEWOUT_FILES) *.ref

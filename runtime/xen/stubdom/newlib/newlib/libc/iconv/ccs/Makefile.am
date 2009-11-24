## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = ccsbi.c \
iso_8859_10.c iso_8859_13.c iso_8859_14.c iso_8859_15.c \
iso_8859_1.c iso_8859_2.c iso_8859_3.c iso_8859_4.c \
iso_8859_5.c iso_8859_6.c iso_8859_7.c iso_8859_8.c \
iso_8859_9.c iso_8859_11.c \
win_1250.c win_1252.c win_1254.c \
win_1256.c win_1258.c win_1251.c \
win_1253.c win_1255.c win_1257.c \
koi8_r.c koi8_u.c koi8_ru.c koi8_uni.c \
iso_ir_111.c \
big5.c \
cp775.c cp850.c cp852.c cp855.c cp866.c \
jis_x0212_1990.c jis_x0201_1976.c jis_x0208_1990.c ksx1001.c \
cns11643_plane1.c cns11643_plane2.c cns11643_plane14.c

## The following interfaces are EL/IX level 2
if ELIX_LEVEL_1
ELIX_SOURCES = ccsbi.c \
iso_8859_10.c iso_8859_13.c iso_8859_14.c iso_8859_15.c \
iso_8859_1.c iso_8859_2.c iso_8859_3.c iso_8859_4.c \
iso_8859_5.c iso_8859_6.c iso_8859_7.c iso_8859_8.c \
iso_8859_9.c iso_8859_11.c \
win_1250.c win_1252.c win_1254.c \
win_1256.c win_1258.c win_1251.c \
win_1253.c win_1255.c win_1257.c \
koi8_r.c koi8_u.c koi8_ru.c koi8_uni.c
iso_ir_111.c \
big5.c \
cp775.c cp850.c cp852.c cp855.c cp866.c \
jis_x0212_1990.c jis_x0201_1976.c jis_x0208_1990.c ksx1001.c \
cns11643_plane1.c cns11643_plane2.c cns11643_plane14.c

else
ELIX_SOURCES =
endif

noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(ELIX_SOURCES)
lib_a_CFLAGS = $(AM_CFLAGS)
noinst_DATA =

SUBDIRS=binary

CHEWOUT_FILES = ccs.def

SUFFIXES = .def

CHEW = ../../../doc/makedoc -f $(srcdir)/../../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/ccs.tex >> $(TARGETDOC)

CLEANFILES = $(CHEWOUT_FILES) *.ref

include $(srcdir)/../../../Makefile.shared

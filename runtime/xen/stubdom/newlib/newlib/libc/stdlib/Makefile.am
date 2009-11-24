## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

GENERAL_SOURCES = \
	__adjust.c 	\
	__atexit.c	\
	__call_atexit.c	\
	__exp10.c 	\
	__ten_mu.c 	\
	_Exit.c		\
	abort.c  	\
	abs.c 		\
	assert.c  	\
	atexit.c	\
	atof.c 		\
	atoff.c		\
	atoi.c  	\
	atol.c		\
	calloc.c	\
	div.c  		\
	dtoa.c 		\
	dtoastub.c 	\
	environ.c	\
	envlock.c	\
	eprintf.c	\
	exit.c 		\
	gdtoa-gethex.c	\
	gdtoa-hexnan.c	\
	getenv.c  	\
	getenv_r.c	\
	labs.c 		\
	ldiv.c  	\
	ldtoa.c		\
	malloc.c  	\
	mblen.c		\
	mblen_r.c	\
	mbstowcs.c	\
	mbstowcs_r.c	\
	mbtowc.c	\
	mbtowc_r.c	\
	mlock.c		\
	mprec.c		\
	mstats.c	\
	rand.c		\
	rand_r.c	\
	realloc.c	\
	strtod.c	\
	strtol.c	\
	strtoul.c	\
	wcstol.c	\
	wcstoul.c	\
	wcstombs.c	\
	wcstombs_r.c	\
	wctomb.c	\
	wctomb_r.c

EXTENDED_SOURCES = \
	cxa_atexit.c	\
	cxa_finalize.c	\
	drand48.c	\
	ecvtbuf.c 	\
	efgcvt.c 	\
	erand48.c	\
	jrand48.c	\
	lcong48.c	\
	lrand48.c	\
	mrand48.c	\
	msize.c		\
	mtrim.c		\
	nrand48.c	\
	rand48.c	\
	seed48.c	\
	srand48.c	\
	strtoll.c	\
	strtoll_r.c	\
	strtoull.c	\
	strtoull_r.c	\
	wcstoll.c	\
	wcstoll_r.c	\
	wcstoull.c	\
	wcstoull_r.c	\
	atoll.c		\
	llabs.c		\
	lldiv.c

ELIX_2_SOURCES = \
	a64l.c		\
	btowc.c		\
	getopt.c	\
	getsubopt.c	\
	l64a.c		\
	malign.c	\
	mbrlen.c	\
	mbrtowc.c	\
	mbsinit.c	\
	mbsrtowcs.c	\
	on_exit.c	\
	valloc.c	\
	wcrtomb.c	\
	wcsrtombs.c	\
	wctob.c

ELIX_2_OBJS = \
	$(lpfx)malignr.$(oext) 	\
	$(lpfx)malloptr.$(oext) \
	$(lpfx)pvallocr.$(oext)	\
	$(lpfx)vallocr.$(oext)

ELIX_3_SOURCES = \
	putenv.c	\
	putenv_r.c	\
	setenv.c	\
	setenv_r.c

ELIX_4_SOURCES = \
	system.c

if ELIX_LEVEL_1
ELIX_SOURCES =
ELIX_OBJS =
else
if ELIX_LEVEL_2
ELIX_SOURCES = $(ELIX_2_SOURCES)
ELIX_OBJS = $(ELIX_2_OBJS)
else
if ELIX_LEVEL_3
ELIX_SOURCES = $(ELIX_2_SOURCES) $(ELIX_3_SOURCES)
ELIX_OBJS = $(ELIX_2_OBJS)
else
ELIX_SOURCES = $(ELIX_2_SOURCES) $(ELIX_3_SOURCES) $(ELIX_4_SOURCES)
ELIX_OBJS = $(ELIX_2_OBJS)
endif
endif
endif

# Because of how libtool moves objects around, mallocr must be built last.
LIBADD_OBJS = $(lpfx)freer.$(oext) $(lpfx)reallocr.$(oext) \
	$(lpfx)callocr.$(oext) $(lpfx)cfreer.$(oext) \
	$(lpfx)mallinfor.$(oext) $(lpfx)mallstatsr.$(oext) \
	$(lpfx)msizer.$(oext) $(lpfx)mallocr.$(oext)

libstdlib_la_LDFLAGS = -Xcompiler -nostdlib

if USE_LIBTOOL
noinst_LTLIBRARIES = libstdlib.la
libstdlib_la_SOURCES = $(GENERAL_SOURCES) $(EXTENDED_SOURCES) $(ELIX_SOURCES)
libstdlib_la_LIBADD =  $(LIBADD_OBJS) $(ELIX_OBJS)
libstdlib_la_DEPENDENCIES = $(LIBADD_OBJS) $(ELIX_OBJS)
LIB_COMPILE = $(LTCOMPILE)
noinst_DATA = objectlist.awk.in
else
noinst_LIBRARIES = lib.a
lib_a_SOURCES = $(GENERAL_SOURCES) $(EXTENDED_SOURCES) $(ELIX_SOURCES)
lib_a_LIBADD = $(LIBADD_OBJS) $(ELIX_OBJS)
lib_a_CFLAGS = $(AM_CFLAGS)
lib_a_DEPENDENCIES = $(LIBADD_OBJS) $(ELIX_OBJS)
LIB_COMPILE = $(COMPILE)
noinst_DATA =
endif # USE_LIBTOOL

include $(srcdir)/../../Makefile.shared

MALLOC_COMPILE = $(LIB_COMPILE) -DINTERNAL_NEWLIB

$(lpfx)mallocr.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOC -c $(srcdir)/mallocr.c -o $@

$(lpfx)freer.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_FREE -c $(srcdir)/mallocr.c -o $@

$(lpfx)reallocr.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_REALLOC -c $(srcdir)/mallocr.c -o $@

$(lpfx)callocr.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_CALLOC -c $(srcdir)/mallocr.c -o $@

$(lpfx)cfreer.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_CFREE -c $(srcdir)/mallocr.c -o $@

$(lpfx)malignr.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_MEMALIGN -c $(srcdir)/mallocr.c -o $@

$(lpfx)vallocr.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_VALLOC -c $(srcdir)/mallocr.c -o $@

$(lpfx)pvallocr.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_PVALLOC -c $(srcdir)/mallocr.c -o $@

$(lpfx)mallinfor.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_MALLINFO -c $(srcdir)/mallocr.c -o $@

$(lpfx)mallstatsr.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOC_STATS -c $(srcdir)/mallocr.c -o $@

$(lpfx)msizer.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOC_USABLE_SIZE -c $(srcdir)/mallocr.c -o $@

$(lpfx)malloptr.$(oext): mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOPT -c $(srcdir)/mallocr.c -o $@

CHEWOUT_FILES= \
	_Exit.def	\
	a64l.def	\
	abort.def	\
	abs.def		\
	assert.def	\
	atexit.def	\
	atof.def 	\
	atoi.def 	\
	atoll.def 	\
	calloc.def	\
	div.def		\
	ecvtbuf.def	\
	efgcvt.def 	\
	envlock.def	\
	exit.def	\
	getenv.def	\
	labs.def	\
	ldiv.def	\
	llabs.def	\
	lldiv.def	\
	malloc.def	\
	mallocr.def	\
	mblen.def	\
	mbstowcs.def	\
	mbtowc.def	\
	mlock.def	\
	mstats.def	\
	on_exit.def	\
	rand.def	\
	rand48.def	\
	strtod.def 	\
	strtol.def 	\
	strtoll.def 	\
	strtoul.def 	\
	strtoull.def 	\
	wcstol.def 	\
	wcstoll.def 	\
	wcstoul.def 	\
	wcstoull.def 	\
	system.def	\
	wcstol.def 	\
	wcstombs.def	\
	wctomb.def	

SUFFIXES = .def

CHEW = ../../doc/makedoc -f $(srcdir)/../../doc/doc.str

.c.def:
	$(CHEW) < $< > $*.def 2> $*.ref
	touch stmp-def

TARGETDOC = ../tmp.texi

doc: $(CHEWOUT_FILES)
	cat $(srcdir)/stdlib.tex >> $(TARGETDOC)

CLEANFILES = $(CHEWOUT_FILES) *.ref

$(lpfx)dtoa.$(oext): dtoa.c mprec.h
$(lpfx)ldtoa.$(oext): ldtoa.c mprec.h
$(lpfx)ecvtbuf.$(oext): ecvtbuf.c mprec.h
$(lpfx)mbtowc_r.$(oext): mbtowc_r.c mbctype.h
	$(LIB_COMPILE) -c -fshort-enums $(srcdir)/mbtowc_r.c -o $@

$(lpfx)mprec.$(oext): mprec.c mprec.h
$(lpfx)strtod.$(oext): strtod.c mprec.h
$(lpfx)gdtoa-gethex.$(oext): gdtoa-gethex.c mprec.h
$(lpfx)gdtoa-hexnan.$(oext): gdtoa-hexnan.c mprec.h
$(lpfx)wctomb_r.$(oext): wctomb_r.c mbctype.h
$(lpfx)drand48.$(oext): drand48.c rand48.h
$(lpfx)erand48.$(oext): erand48.c rand48.h
$(lpfx)jrand48.$(oext): jrand48.c rand48.h
$(lpfx)lcong48.$(oext): lcong48.c rand48.h
$(lpfx)lrand48.$(oext): lrand48.c rand48.h
$(lpfx)mrand48.$(oext): mrand48.c rand48.h
$(lpfx)nrand48.$(oext): nrand48.c rand48.h
$(lpfx)rand48.$(oext): rand48.c rand48.h
$(lpfx)seed48.$(oext): seed48.c rand48.h
$(lpfx)srand48.$(oext): srand48.c rand48.h

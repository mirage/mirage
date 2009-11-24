## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

# hack: putting $(newlib_basedir)/libm/common into INCLUDES forces automake
# to output a definition for newlib_basedir.
INCLUDES = -I $(newlib_basedir)/libm/common $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

lib_a_SOURCES = setjmp.S
lib_a_CCASFLAGS = $(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

lib_a_LIBADD = $(lpfx)malloc.o \
	$(lpfx)free.o \
	$(lpfx)realloc.o \
	$(lpfx)calloc.o \
	$(lpfx)cfree.o \
	$(lpfx)malign.o \
	$(lpfx)valloc.o \
	$(lpfx)pvalloc.o \
	$(lpfx)mallinfo.o \
	$(lpfx)mallstats.o \
	$(lpfx)msize.o \
	$(lpfx)mallopt.o \
	$(lpfx)mallocr.o \
	$(lpfx)freer.o \
	$(lpfx)reallocr.o \
	$(lpfx)callocr.o

lib_a_DEPENDENCIES = $(lib_a_LIBADD)

MALLOC_COMPILE = $(COMPILE)

$(lpfx)malloc.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOC -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)free.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_FREE -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)realloc.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_REALLOC -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)calloc.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_CALLOC -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)cfree.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_CFREE -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)malign.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_MEMALIGN -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)valloc.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_VALLOC -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)pvalloc.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_PVALLOC -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)mallinfo.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_MALLINFO -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)mallstats.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOC_STATS -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)msize.o: tiny-malloc.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOC_USABLE_SIZE -c $(srcdir)/tiny-malloc.c -o $@

$(lpfx)mallopt.o: mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOPT -c $(srcdir)/mallocr.c -o $@

$(lpfx)mallocr.o: mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_MALLOC -c $(srcdir)/mallocr.c -o $@

$(lpfx)freer.o: mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_FREE -c $(srcdir)/mallocr.c -o $@

$(lpfx)reallocr.o: mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_REALLOC -c $(srcdir)/mallocr.c -o $@

$(lpfx)callocr.o: mallocr.c
	$(MALLOC_COMPILE) -DDEFINE_CALLOC -c $(srcdir)/mallocr.c -o $@


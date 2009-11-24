## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

AM_CCASFLAGS = $(INCLUDES)

noinst_LIBRARIES = lib.a

if SH64
lib_a_SOURCES = memcpy.S memset.S setjmp.S strcpy.S strlen.S strcmp.S strncpy.S
else
lib_a_SOURCES = memcpy.S memset.S setjmp.S strcpy.S strlen.S strcmp.S
endif

lib_a_CCASFLAGS=$(AM_CCASFLAGS)
lib_a_CFLAGS=$(AM_CFLAGS)

$(lpfx)memcpy.o: asm.h
$(lpfx)memset.o: asm.h
$(lpfx)setjmp.o: asm.h
$(lpfx)strcpy.o: asm.h
$(lpfx)strcmp.o: asm.h
$(lpfx)strncpy.o: asm.h

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../..
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host

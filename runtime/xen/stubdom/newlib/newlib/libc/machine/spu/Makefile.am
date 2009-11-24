## Process this file with automake to generate Makefile.in

AUTOMAKE_OPTIONS = cygnus

INCLUDES = $(NEWLIB_CFLAGS) $(CROSS_CFLAGS) $(TARGET_CFLAGS)

noinst_LIBRARIES = lib.a

AM_CCASFLAGS = $(INCLUDES)

lib_a_SOURCES = setjmp.S clearerr.c creat.c fclose.c feof.c ferror.c fflush.c \
	fgetc.c fgetpos.c fgets.c fileno.c fiprintf.S fiscanf.S fopen.c \
	fprintf.S fputc.c fputs.c fread.c freopen.c fscanf.S fseek.c \
	fsetpos.c ftell.c fwrite.c getc.c getchar.c gets.c iprintf.S \
	iscanf.S memcpy.c memmove.c memset.c perror.c printf.S \
	putc.c putchar.c puts.c remove.c rename.c rewind.c scanf.S \
	setbuf.c setvbuf.c siprintf.S siscanf.S sleep.c sniprintf.S \
	snprintf.S sprintf.S sscanf.S stdio.c strcat.c strchr.c strcmp.c \
	strcpy.c strcspn.c strlen.c strncat.c strncmp.c strncpy.c strpbrk.c \
	strrchr.c strspn.c strxfrm.c tmpfile.c tmpnam.c ungetc.c usleep.c \
	vfiprintf.c vfiscanf.c vfprintf.c vfscanf.c viprintf.c viscanf.c \
	vprintf.c vscanf.c vsiprintf.c vsiscanf.c vsniprintf.c vsnprintf.c \
	vsprintf.c vsscanf.c stack_reg_va.S

lib_a_CCASFLAGS = $(AM_CCASFLAGS)
lib_a_CFLAGS = $(AM_CFLAGS)

ACLOCAL_AMFLAGS = -I ../../.. -I ../../../.. 
CONFIG_STATUS_DEPENDENCIES = $(newlib_basedir)/configure.host


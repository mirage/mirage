#ifndef _STDIO_H
#define _STDIO_H

#include <sys/cdefs.h>
#include <sys/types.h>
#include <stdarg.h>
#include <endian.h>

__BEGIN_DECLS

struct __stdio_file;
typedef struct __stdio_file FILE;

extern FILE *stdin, *stdout, *stderr;

FILE *fopen (const char *path, const char *mode) __THROW;
FILE *fdopen (int fildes, const char *mode) __THROW;
FILE *freopen (const char *path, const char *mode, FILE *stream) __THROW;

int printf(const char *format, ...) __THROW __attribute__((__format__(__printf__,1,2)));
int fprintf(FILE *stream, const char *format, ...) __THROW __attribute__((__format__(__printf__,2,3)));
int sprintf(char *str, const char *format, ...) __THROW __attribute__((__format__(__printf__,2,3)));
int snprintf(char *str, size_t size, const char *format, ...) __THROW __attribute__((__format__(__printf__,3,4)));
int asprintf(char **ptr, const char* format, ...) __THROW __attribute_malloc__ __attribute__((__format__(__printf__,2,3)));

int scanf(const char *format, ...) __THROW __attribute__((__format__(__scanf__,1,2)));
int fscanf(FILE *stream, const char *format, ...) __THROW __attribute__((__format__(__scanf__,2,3)));
int sscanf(const char *str, const char *format, ...) __THROW __attribute__((__format__(__scanf__,2,3)));

int vprintf(const char *format, va_list ap) __THROW __attribute__((__format__(__printf__,1,0)));
int vfprintf(FILE *stream, const char *format, va_list ap) __THROW __attribute__((__format__(__printf__,2,0)));
int vsprintf(char *str, const char *format, va_list ap) __THROW __attribute__((__format__(__printf__,2,0)));
int vsnprintf(char *str, size_t size, const char *format, va_list ap) __THROW __attribute__((__format__(__printf__,3,0)));

int fdprintf(int fd, const char *format, ...) __THROW __attribute__((__format__(__printf__,2,3)));
int vfdprintf(int fd, const char *format, va_list ap) __THROW __attribute__((__format__(__printf__,2,0)));

int vscanf(const char *format, va_list ap) __THROW __attribute__((__format__(__scanf__,1,0)));
int vsscanf(const char *str, const char *format, va_list ap) __THROW __attribute__((__format__(__scanf__,2,0)));
int vfscanf(FILE *stream, const char *format, va_list ap) __THROW __attribute__((__format__(__scanf__,2,0)));

int fgetc(FILE *stream) __THROW;
int fgetc_unlocked(FILE *stream) __THROW;
char *fgets(char *s, int size, FILE *stream) __THROW;
char *fgets_unlocked(char *s, int size, FILE *stream) __THROW;

char *gets(char *s) __THROW;
int ungetc(int c, FILE *stream) __THROW;
int ungetc_unlocked(int c, FILE *stream) __THROW;

int fputc(int c, FILE *stream) __THROW;
int fputc_unlocked(int c, FILE *stream) __THROW;
int fputs(const char *s, FILE *stream) __THROW;
int fputs_unlocked(const char *s, FILE *stream) __THROW;

int getc(FILE *stream) __THROW;
int getchar(void) __THROW;
int putchar(int c) __THROW;
int putchar_unlocked(int c) __THROW;

#if !defined(__cplusplus)
#define putc(c,stream) fputc(c,stream)
#define putchar(c) fputc(c,stdout)
#define putc_unlocked(c,stream) fputc_unlocked(c,stream)
#define putchar_unlocked(c) fputc_unlocked(c,stdout)
#else
inline int putc(int c, FILE *stream) __THROW { return fputc(c,stream); }
inline int putc_unlocked(int c, FILE *stream) __THROW { return fputc_unlocked(c,stream); }
#endif

#if !defined(__cplusplus)
#define getc(stream) fgetc(stream)
#define getchar() fgetc(stdin)
#define getc_unlocked(stream) fgetc_unlocked(stream)
#define getchar_unlocked() fgetc_unlocked(stdin)
#else
inline int getc_unlocked(FILE *stream) __THROW { return fgetc_unlocked(stream); }
inline int getchar_unlocked(void) __THROW { return fgetc_unlocked(stdin); }
#endif

int puts(const char *s) __THROW;

int fseek(FILE *stream, long offset, int whence) __THROW;
int fseek_unlocked(FILE *stream, long offset, int whence) __THROW;
long ftell(FILE *stream) __THROW;
long ftell_unlocked(FILE *stream) __THROW;
int fseeko(FILE *stream, off_t offset, int whence) __THROW;
int fseeko_unlocked(FILE *stream, off_t offset, int whence) __THROW;
off_t ftello(FILE *stream) __THROW;
off_t ftello_unlocked(FILE *stream) __THROW;

#if __WORDSIZE == 32
int fseeko64(FILE *stream, loff_t offset, int whence) __THROW;
int fseeko64_unlocked(FILE *stream, loff_t offset, int whence) __THROW;
loff_t ftello64(FILE *stream) __THROW;
loff_t ftello64_unlocked(FILE *stream) __THROW;

#if defined _FILE_OFFSET_BITS && _FILE_OFFSET_BITS == 64
#define off_t loff_t
#define fseeko(foo,bar,baz) fseeko64(foo,bar,baz)
#define ftello(foo) ftello64(foo)
#endif

#endif

void rewind(FILE *stream) __THROW;
int fgetpos(FILE *stream, fpos_t *pos) __THROW;
int fsetpos(FILE *stream, fpos_t *pos) __THROW;

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream) __THROW;
size_t fread_unlocked(void *ptr, size_t size, size_t nmemb, FILE *stream) __THROW;

size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream) __THROW;
size_t fwrite_unlocked(const void *ptr, size_t size, size_t nmemb, FILE *stream) __THROW;

int fflush(FILE *stream) __THROW;
int fflush_unlocked(FILE *stream) __THROW;

int fclose(FILE *stream) __THROW;
int fclose_unlocked(FILE *stream) __THROW;

int feof(FILE *stream) __THROW;
int feof_unlocked(FILE *stream) __THROW;
int ferror(FILE *stream) __THROW;
int ferror_unlocked(FILE *stream) __THROW;
int fileno(FILE *stream) __THROW;
int fileno_unlocked(FILE *stream) __THROW;
void clearerr(FILE *stream) __THROW;
void clearerr_unlocked(FILE *stream) __THROW;

int remove(const char *pathname) __THROW;
int rename(const char *oldpath, const char *newpath) __THROW;

void perror(const char *s) __THROW;

#define EOF (-1)

#define BUFSIZ 128

#define _IONBF 0
#define _IOLBF 1
#define _IOFBF 2

int setvbuf(FILE *stream, char *buf, int mode , size_t size) __THROW;
int setvbuf_unlocked(FILE *stream, char *buf, int mode , size_t size) __THROW;

#if !defined(__cplusplus)
#define setbuf(stream,buf) setvbuf(stream,buf,buf?_IOFBF:_IONBF,BUFSIZ)
#define setbuffer(stream,buf,size) setvbuf(stream,buf,buf?_IOFBF:_IONBF,size)
#define setlinebuf(stream) setvbuf(stream,0,_IOLBF,BUFSIZ)
#else
inline int setbuf(FILE *stream, char *buf) __THROW
  { return setvbuf(stream,buf,buf?_IOFBF:_IONBF,BUFSIZ); }
inline int setbuffer(FILE *stream, char *buf, size_t size) __THROW
  { return setvbuf(stream,buf,buf?_IOFBF:_IONBF,size); }
inline int setlinebuf(FILE *stream) __THROW
  { return setvbuf(stream,0,_IOLBF,BUFSIZ); }
#endif

FILE *popen(const char *command, const char *type) __THROW;
int pclose(FILE *stream) __THROW;

#ifndef SEEK_SET
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#endif

#define L_tmpnam 128
#define P_tmpdir "/tmp"
char* tmpnam(char *s) __THROW;	/* DO NOT USE!!! Use mkstemp instead! */
char* tempnam(char* dir,char* _template);	/* dito */
FILE* tmpfile(void) __THROW;
FILE* tmpfile_unlocked(void) __THROW;

#define FILENAME_MAX 4095
#define FOPEN_MAX 16

#define TMP_MAX 10000

/* this is so bad, we moved it to -lcompat */
#define L_ctermid 9
char* ctermid(char* s); /* returns "/dev/tty" */

void flockfile(FILE* f) __THROW;
void funlockfile(FILE* f) __THROW;
int ftrylockfile (FILE *__stream) __THROW;

#ifdef _GNU_SOURCE
int vasprintf(char **strp, const char *fmt, va_list ap);
ssize_t getline(char **lineptr, size_t *n, FILE *stream);
ssize_t getdelim(char **lineptr, size_t *n, int delim, FILE *stream);
#endif

__END_DECLS

#endif

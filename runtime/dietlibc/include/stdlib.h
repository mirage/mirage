#ifndef _STDLIB_H
#define _STDLIB_H

#ifndef __ASSEMBLER__

#include <sys/cdefs.h>
#include <sys/types.h>
#include <alloca.h>

__BEGIN_DECLS

void *calloc(size_t nmemb, size_t size) __THROW __attribute_malloc__;
void *malloc(size_t size)  __THROW __attribute_malloc__;
void free(void *ptr) __THROW;
void *realloc(void *ptr, size_t size) __THROW __attribute_malloc__;

char *getenv(const char *name) __THROW __pure;
int putenv(const char *string) __THROW;
int setenv(const char *name, const char *value, int overwrite) __THROW;
int unsetenv(const char *name) __THROW;

int system (const char * string) __THROW;
int atexit(void (*function)(void)) __THROW;

float strtof(const char *nptr, char **endptr) __THROW;
double strtod(const char *nptr, char **endptr) __THROW;
long double strtold(const char *nptr, char **endptr) __THROW;
long int strtol(const char *nptr, char **endptr, int base) __THROW;
unsigned long int strtoul(const char *nptr, char **endptr, int base) __THROW;

extern int __ltostr(char *s, unsigned int size, unsigned long i, unsigned int base, int UpCase) __THROW;
extern int __dtostr(double d,char *buf,unsigned int maxlen,unsigned int prec,unsigned int prec2,int g) __THROW;

#if !defined(__STRICT_ANSI__) || __STDC_VERSION__ + 0 >= 199900L
__extension__ long long int strtoll(const char *nptr, char **endptr, int base) __THROW;
__extension__ unsigned long long int strtoull(const char *nptr, char **endptr, int base) __THROW;
__extension__ int __lltostr(char *s, unsigned int size, unsigned long long i, unsigned int base, int UpCase) __THROW;
#endif

int atoi(const char *nptr) __THROW;
long int atol(const char *nptr) __THROW;
double atof(const char *nptr) __THROW;
__extension__ long long int atoll(const char *nptr);

void exit(int status) __THROW __attribute__((__noreturn__));
void abort(void) __THROW;

extern int rand(void) __THROW;
extern int rand_r(unsigned int *seed) __THROW;
extern void srand(unsigned int seed) __THROW;
#ifdef _BSD_SOURCE
extern int random(void) __THROW __attribute_dontuse__;
extern void srandom(unsigned int seed) __THROW __attribute_dontuse__;
#endif

typedef unsigned short randbuf[3];
double drand48(void) __THROW;
long lrand48(void) __THROW;
long mrand48(void) __THROW;
void srand48(long seed) __THROW;
unsigned short *seed48(randbuf buf) __THROW;
void lcong48(unsigned short param[7]) __THROW;
long jrand48(randbuf buf) __THROW;
long nrand48(randbuf buf) __THROW;
double erand48(randbuf buf) __THROW;

void qsort(void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *));
void *bsearch(const void *key, const void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *));

extern char **environ;

char *realpath(const char *path, char *resolved_path) __THROW;

int mkstemp(char *_template);
char* mkdtemp(char *_template);

char* mktemp(char *_template);

int abs(int i) __THROW __attribute__((__const__));
long int labs(long int i) __THROW __attribute__((__const__));
__extension__ long long int llabs(long long int i) __THROW __attribute__((__const__));

#ifdef _XOPEN_SOURCE
int grantpt (int fd) __THROW;
int unlockpt (int fd) __THROW;
char *ptsname (int fd) __THROW;
#endif

#endif

#define EXIT_FAILURE 1
#define EXIT_SUCCESS 0

#define RAND_MAX 	0x7ffffffe

#define MB_CUR_MAX 1

/* now these functions are the greatest bullshit I have ever seen.
 * The ISO people must be out of their minds. */

typedef struct { int quot,rem; } div_t;
typedef struct { long quot,rem; } ldiv_t;

div_t div(int numerator, int denominator);
ldiv_t ldiv(long numerator, long denominator);

#ifdef _GNU_SOURCE
typedef struct { long long quot,rem; } lldiv_t;
lldiv_t lldiv(long long numerator, long long denominator);

int clearenv(void);
#endif

int mbtowc(wchar_t *pwc, const char *s, size_t n) __THROW;
int wctomb(char *s, wchar_t wc) __THROW;
size_t mbstowcs(wchar_t *dest, const char *src, size_t n) __THROW;
int mblen(const char* s,size_t n) __THROW __pure;

__END_DECLS

#endif

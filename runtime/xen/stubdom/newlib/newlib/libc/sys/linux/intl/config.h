#define HAVE_ICONV 1
#define HAVE_STRING_H 1
#define HAVE_MEMPCPY 1
#define HAVE_STRCHR 1
#define HAVE_STRDUP 1
#define HAVE_MMAP 1
#define HAVE_STRTOUL 1
#define HAVE_ALLOCA_H 1
#define HAVE_MALLOC_H 1
#define HAVE_STRCASECMP 1
#define HAVE_WEAK_SYMBOLS 1
#define HAVE_GNU_LD 1
#define HAVE_ELF 1
#define __ASSUME_REALTIME_SIGNALS 1
#define ASM_GLOBAL_DIRECTIVE .global

#define TEMP_FAILURE_RETRY(expression) \
  (__extension__                                                              \
    ({ long int __result;                                                     \
       do __result = (long int) (expression);                                 \
       while (__result == -1L && errno == EINTR);                             \
       __result; }))

#define UINT32_C(c)    c ## U

#include <machine/sysdep.h>
#include <features.h>

#define _LIBC 1

#ifndef _LINUX_STRING_H_
#define _LINUX_STRING_H_

#include <xen/types.h>	/* for size_t */

#ifdef __cplusplus
extern "C" {
#endif

#define __kernel_size_t size_t

extern char * strpbrk(const char *,const char *);
extern char * strsep(char **,const char *);
extern __kernel_size_t strspn(const char *,const char *);


/*
 * Include machine specific inline routines
 */
#include <asm/string.h>

/*
 * These string functions are considered too dangerous for normal use.
 * Use safe_strcpy(), safe_strcat(), strlcpy(), strlcat() as appropriate.
 */
#define strcpy  __xen_has_no_strcpy__
#define strcat  __xen_has_no_strcat__
#define strncpy __xen_has_no_strncpy__
#define strncat __xen_has_no_strncat__

#ifndef __HAVE_ARCH_STRLCPY
extern size_t strlcpy(char *,const char *, __kernel_size_t);
#endif
#ifndef __HAVE_ARCH_STRLCAT
extern size_t strlcat(char *,const char *, __kernel_size_t);
#endif
#ifndef __HAVE_ARCH_STRCMP
extern int strcmp(const char *,const char *);
#endif
#ifndef __HAVE_ARCH_STRNCMP
extern int strncmp(const char *,const char *,__kernel_size_t);
#endif
#ifndef __HAVE_ARCH_STRNICMP
extern int strnicmp(const char *, const char *, __kernel_size_t);
#endif
#ifndef __HAVE_ARCH_STRCHR
extern char * strchr(const char *,int);
#endif
#ifndef __HAVE_ARCH_STRRCHR
extern char * strrchr(const char *,int);
#endif
#ifndef __HAVE_ARCH_STRSTR
extern char * strstr(const char *,const char *);
#endif
#ifndef __HAVE_ARCH_STRLEN
extern __kernel_size_t strlen(const char *);
#endif
#ifndef __HAVE_ARCH_STRNLEN
extern __kernel_size_t strnlen(const char *,__kernel_size_t);
#endif

#ifndef __HAVE_ARCH_MEMSET
extern void * memset(void *,int,__kernel_size_t);
#endif
#ifndef __HAVE_ARCH_MEMCPY
extern void * memcpy(void *,const void *,__kernel_size_t);
#endif
#ifndef __HAVE_ARCH_MEMMOVE
extern void * memmove(void *,const void *,__kernel_size_t);
#endif
#ifndef __HAVE_ARCH_MEMSCAN
extern void * memscan(void *,int,__kernel_size_t);
#endif
#ifndef __HAVE_ARCH_MEMCMP
extern int memcmp(const void *,const void *,__kernel_size_t);
#endif
#ifndef __HAVE_ARCH_MEMCHR
extern void * memchr(const void *,int,__kernel_size_t);
#endif

#ifdef __cplusplus
}
#endif

#define is_char_array(x) __builtin_types_compatible_p(typeof(x), char[])

/* safe_xxx always NUL-terminates and returns !=0 if result is truncated. */
#define safe_strcpy(d, s) ({                    \
    BUILD_BUG_ON(!is_char_array(d));            \
    (strlcpy(d, s, sizeof(d)) >= sizeof(d));    \
})
#define safe_strcat(d, s) ({                    \
    BUILD_BUG_ON(!is_char_array(d));            \
    (strlcat(d, s, sizeof(d)) >= sizeof(d));    \
})

#endif /* _LINUX_STRING_H_ */

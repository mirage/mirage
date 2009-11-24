#ifndef _POSIX_LIMITS_H
#define _POSIX_LIMITS_H

#include <mini-os/arch_limits.h>

#define CHAR_BIT        8

#define SCHAR_MAX       0x7f
#define SCHAR_MIN       (-SCHAR_MAX-1)
#define UCHAR_MAX       0xff

#ifdef __CHAR_UNSIGNED__
# define CHAR_MIN       0
# define CHAR_MAX       UCHAR_MAX
#else
# define CHAR_MIN       SCHAR_MIN
# define CHAR_MAX       SCHAR_MAX
#endif

#define INT_MAX         0x7fffffff
#define INT_MIN         (-INT_MAX-1)
#define UINT_MAX        0xffffffff

#define SHRT_MIN	(-0x8000)
#define SHRT_MAX        0x7fff
#define USHRT_MAX       0xffff

#if defined(__x86_64__) || defined(__ia64__)
# define LONG_MAX       0x7fffffffffffffffL
# define ULONG_MAX      0xffffffffffffffffUL
#else
# define LONG_MAX       0x7fffffffL
# define ULONG_MAX      0xffffffffUL
#endif
#define LONG_MIN        (-LONG_MAX-1L)

#define LLONG_MAX       0x7fffffffffffffffLL
#define LLONG_MIN       (-LLONG_MAX-1LL)
#define ULLONG_MAX      0xffffffffffffffffULL

#define LONG_LONG_MIN   LLONG_MIN
#define LONG_LONG_MAX   LLONG_MAX
#define ULONG_LONG_MAX  ULLONG_MAX

#define PATH_MAX __PAGE_SIZE
#define PAGE_SIZE __PAGE_SIZE

#endif /* _POSIX_LIMITS_H */

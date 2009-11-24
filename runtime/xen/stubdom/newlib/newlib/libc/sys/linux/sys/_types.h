/* ANSI C namespace clean utility typedefs */

/* This file defines various typedefs needed by the system calls that support
   the C library.  Basically, they're just the POSIX versions with an '_'
   prepended.  This file lives in the `sys' directory so targets can provide
   their own if desired (or they can put target dependant conditionals here).
*/

#ifndef	_SYS__TYPES_H
#define _SYS__TYPES_H

typedef long _off_t;
__extension__ typedef long long _off64_t;

typedef long _fpos_t;
__extension__ typedef long long _fpos64_t;

#if defined(__INT_MAX__) && __INT_MAX__ == 2147483647
typedef int _ssize_t;
#else
typedef long _ssize_t;
#endif

#define __need_wint_t
#include <stddef.h>

/* Conversion state information.  */
typedef struct
{
  int __count;
  union
  {
    wint_t __wch;
    unsigned char __wchb[4];
  } __value;		/* Value so far.  */
} _mbstate_t;

struct __flock_mutex_t_tmp;
typedef struct
{
  int __a;
  int __b;
  struct
  {
    long int __c1;
    int __c2;
  } __c;
  int __d;
  struct __flock_mutex_t_tmp * __e;
} __flock_mutex_t;

typedef struct { __flock_mutex_t mutex; } _flock_t;

#endif	/* _SYS__TYPES_H */

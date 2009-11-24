/* libc/sys/linux/sys/errno.h - Errno variable and codes */

/* Written 2000 by Werner Almesberger */


#ifndef _SYS_ERRNO_H
#define _SYS_ERRNO_H

/* --- from newlin's sys/errno.h --- */

#include <sys/reent.h>

#ifndef _REENT_ONLY
#define errno (*__errno())
extern int *__errno _PARAMS ((void));
#endif

extern __IMPORT _CONST char * _CONST _sys_errlist[];
extern __IMPORT int _sys_nerr;

#define __errno_r(ptr) ((ptr)->_errno)

/* --- end of slight redundancy (the use of struct _reent->_errno is
       hard-coded in perror.c so why pretend anything else could work too ? */

#define __set_errno(x) (errno = (x))

#include <asm/errno.h>

#define ENOTSUP EOPNOTSUPP
#define EFTYPE          79              /* Inappropriate file type or format */
#define EILSEQ          84

#endif

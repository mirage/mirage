/* The weak pthread functions for Linux.
   Copyright (C) 1996,1997,1998,1999,2000,2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the GNU C Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

#include <errno.h>
#include <limits.h>
#include <stdlib.h>
#include <shlib-compat.h>
#include <bp-sym.h>
#include "libc-symbols.h"

extern int __pthread_return_0 (void);
extern int __pthread_return_1 (void);
extern void __pthread_return_void (void);
extern void weak_function pthread_exit (void *__retval)
     __attribute__ ((noreturn));

/* Those are pthread functions which return 0 if successful. */
weak_alias (__pthread_return_0, BP_SYM (__libc_pthread_attr_init_2_1))
versioned_symbol (libpthread, BP_SYM (__libc_pthread_attr_init_2_1),
		  BP_SYM (pthread_attr_init), GLIBC_2_1);
#if SHLIB_COMPAT(libpthread, GLIBC_2_0, GLIBC_2_1)
weak_alias (__pthread_return_0, BP_SYM (__libc_pthread_attr_init_2_0))
compat_symbol (libpthread, BP_SYM (__libc_pthread_attr_init_2_0),
	       BP_SYM (pthread_attr_init), GLIBC_2_0);
#endif
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_destroy))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_setdetachstate))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_getdetachstate))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_setschedparam))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_getschedparam))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_setschedpolicy))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_getschedpolicy))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_setinheritsched))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_getinheritsched))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_setscope))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_getscope))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_setstackaddr))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_getstackaddr))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_setstacksize))
weak_alias (__pthread_return_0, BP_SYM (pthread_attr_getstacksize))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutex_init))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutex_destroy))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutex_lock))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutex_trylock))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutex_unlock))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutexattr_init))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutexattr_destroy))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutexattr_settype))
weak_alias (__pthread_return_0, BP_SYM (pthread_mutexattr_gettype))
weak_alias (__pthread_return_0, BP_SYM (pthread_condattr_init))
weak_alias (__pthread_return_0, BP_SYM (pthread_condattr_destroy))
weak_alias (__pthread_return_0, BP_SYM (pthread_setschedparam))
weak_alias (__pthread_return_0, BP_SYM (pthread_getschedparam))
weak_alias (__pthread_return_0, BP_SYM (pthread_getcancelstate))
weak_alias (__pthread_return_0, BP_SYM (pthread_setcancelstate))
weak_alias (__pthread_return_0, BP_SYM (pthread_setcanceltype))
weak_alias (__pthread_return_0, pthread_setconcurrency)
weak_alias (__pthread_return_0, pthread_getconcurrency)
weak_alias (__pthread_return_0, pthread_self)
weak_alias (__pthread_return_0, BP_SYM (pthread_cond_init))
weak_alias (__pthread_return_0, BP_SYM (pthread_cond_destroy))
weak_alias (__pthread_return_0, BP_SYM (pthread_cond_wait))
weak_alias (__pthread_return_0, BP_SYM (pthread_cond_timedwait))
weak_alias (__pthread_return_0, BP_SYM (pthread_cond_signal))
weak_alias (__pthread_return_0, BP_SYM (pthread_cond_broadcast))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlock_init))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlock_destroy))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlock_rdlock))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlock_wrlock))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlock_tryrdlock))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlock_trywrlock))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlock_unlock))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlockattr_init))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlockattr_destroy))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlockattr_setpshared))
weak_alias (__pthread_return_0, BP_SYM (pthread_rwlockattr_getpshared))


/* Those are pthread functions which return 1 if successful. */
weak_alias (__pthread_return_1, pthread_equal)

/* pthread_exit () is a special case. */
void
weak_function
pthread_exit (void *retval)
{
  exit (EXIT_SUCCESS);
}

int
__pthread_return_0 (void)
{
  return 0;
}

int
__pthread_return_1 (void)
{
  return 1;
}

void
__pthread_return_void (void)
{
}

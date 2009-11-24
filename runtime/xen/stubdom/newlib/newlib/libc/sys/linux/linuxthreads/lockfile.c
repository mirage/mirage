/* lockfile - Handle locking and unlocking of stream.
   Copyright (C) 1996, 1998, 2000 Free Software Foundation, Inc.
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

#include <sys/lock.h>
#include <stdio.h>
#include <pthread.h>
#include "internals.h"

#ifdef USE_IN_LIBIO
#include "../libio/libioP.h"
#endif

#ifndef SHARED
/* We need a hook to force this file to be linked in when static
   libpthread is used.  */
const int __pthread_provide_lockfile = 0;
#endif

void
__flockfile (FILE *stream)
{
  __lock_acquire_recursive (*(_LOCK_RECURSIVE_T *)&stream->_lock);
}
#undef _IO_flockfile
strong_alias (__flockfile, _IO_flockfile)
weak_alias (__flockfile, flockfile);


void
__funlockfile (FILE *stream)
{
  __lock_release_recursive (*(_LOCK_RECURSIVE_T *)&stream->_lock);
}
#undef _IO_funlockfile
strong_alias (__funlockfile, _IO_funlockfile)
weak_alias (__funlockfile, funlockfile);


int
__ftrylockfile (FILE *stream)
{
  return __lock_try_acquire_recursive (*(_LOCK_RECURSIVE_T *)&stream->_lock);
}
strong_alias (__ftrylockfile, _IO_ftrylockfile)
weak_alias (__ftrylockfile, ftrylockfile);

void
__flockfilelist(void)
{
#ifdef USE_IN_LIBIO
  _IO_list_lock();
#endif
}

void
__funlockfilelist(void)
{
#ifdef USE_IN_LIBIO
  _IO_list_unlock();
#endif
}

void
__fresetlockfiles (void)
{
#ifdef USE_IN_LIBIO
  _IO_ITER i;

  pthread_mutexattr_t attr;

  __pthread_mutexattr_init (&attr);
  __pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE_NP);

  for (i = _IO_iter_begin(); i != _IO_iter_end(); i = _IO_iter_next(i))
    __pthread_mutex_init (_IO_iter_file(i)->_lock, &attr);

  __pthread_mutexattr_destroy (&attr);

  _IO_list_resetlock();
#endif
}

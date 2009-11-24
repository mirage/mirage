/*
FUNCTION
<<__env_lock>>, <<__env_unlock>>---lock environ variable

INDEX
	__env_lock
INDEX
	__env_unlock

ANSI_SYNOPSIS
	#include "envlock.h"
	void __env_lock (struct _reent *<[reent]>);
	void __env_unlock (struct _reent *<[reent]>);

TRAD_SYNOPSIS
	void __env_lock(<[reent]>)
	struct _reent *<[reent]>;

	void __env_unlock(<[reent]>)
	struct _reent *<[reent]>;

DESCRIPTION
The <<setenv>> family of routines call these functions when they need to
modify the environ variable.  The version of these routines supplied in the
library use the lock API defined in sys/lock.h.  If multiple threads of
execution can call <<setenv>>, or if <<setenv>> can be called reentrantly,
then you need to define your own versions of these functions in order to
safely lock the memory pool during a call.  If you do not, the memory pool
may become corrupted.

A call to <<setenv>> may call <<__env_lock>> recursively; that is,
the sequence of calls may go <<__env_lock>>, <<__env_lock>>,
<<__env_unlock>>, <<__env_unlock>>.  Any implementation of these
routines must be careful to avoid causing a thread to wait for a lock
that it already holds.
*/

#include "envlock.h"
#include <sys/lock.h>

#ifndef __SINGLE_THREAD__
__LOCK_INIT_RECURSIVE(static, __env_lock_object);
#endif

void
__env_lock (ptr)
     struct _reent *ptr;
{
#ifndef __SINGLE_THREAD__
  __lock_acquire_recursive (__env_lock_object);
#endif
}

void
__env_unlock (ptr)
     struct _reent *ptr;
{
#ifndef __SINGLE_THREAD__
  __lock_release_recursive (__env_lock_object);
#endif
}

/*
 *  Common routine to implement atexit-like functionality.
 */

#include <stddef.h>
#include <stdlib.h>
#include <reent.h>
#include <sys/lock.h>
#include "atexit.h"


/*
 * Register a function to be performed at exit or on shared library unload.
 */

int
_DEFUN (__register_exitproc,
	(type, fn, arg, d),
	int type _AND
	void (*fn) (void) _AND
	void *arg _AND
	void *d)
{
  struct _on_exit_args * args;
  register struct _atexit *p;

#ifndef __SINGLE_THREAD__
  __LOCK_INIT(static, lock);

  __lock_acquire(lock);
#endif

  p = _GLOBAL_REENT->_atexit;
  if (p == NULL)
    _GLOBAL_REENT->_atexit = p = &_GLOBAL_REENT->_atexit0;
  if (p->_ind >= _ATEXIT_SIZE)
    {
#ifndef _ATEXIT_DYNAMIC_ALLOC
      return -1;
#else
      p = (struct _atexit *) malloc (sizeof *p);
      if (p == NULL)
	{
#ifndef __SINGLE_THREAD__
	  __lock_release(lock);
#endif
	  return -1;
	}
      p->_ind = 0;
      p->_next = _GLOBAL_REENT->_atexit;
      _GLOBAL_REENT->_atexit = p;
#ifndef _REENT_SMALL
      p->_on_exit_args._fntypes = 0;
      p->_on_exit_args._is_cxa = 0;
#endif
#endif
    }

  if (type != __et_atexit)
    {
#ifdef _REENT_SMALL
      args = p->_on_exit_args_ptr;
      if (args == NULL)
	{
	  args = malloc (sizeof * p->_on_exit_args_ptr);
	  if (args == NULL)
	    {
#ifndef __SINGLE_THREAD__
	      __lock_release(lock);
#endif
	      return -1;
	    }
	  args->_fntypes = 0;
	  args->_is_cxa = 0;
	  p->_on_exit_args_ptr = args;
	}
#else
      args = &p->_on_exit_args;
#endif
      args->_fnargs[p->_ind] = arg;
      args->_fntypes |= (1 << p->_ind);
      args->_dso_handle[p->_ind] = d;
      if (type == __et_cxa)
	args->_is_cxa |= (1 << p->_ind);
    }
  p->_fns[p->_ind++] = fn;
#ifndef __SINGLE_THREAD__
  __lock_release(lock);
#endif
  return 0;
}

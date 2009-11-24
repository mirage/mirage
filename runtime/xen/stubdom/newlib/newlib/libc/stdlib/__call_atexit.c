/*
 * COmmon routine to call call registered atexit-like routines.
 */


#include <stdlib.h>
#include <reent.h>
#include "atexit.h"

/*
 * Call registered exit handlers.  If D is null then all handlers are called,
 * otherwise only the handlers from that DSO are called.
 */

void 
_DEFUN (__call_exitprocs, (code, d),
	int code _AND _PTR d)
{
  register struct _atexit *p;
  struct _atexit **lastp;
  register struct _on_exit_args * args;
  register int n;
  int i;
  void (*fn) (void);

 restart:

  p = _GLOBAL_REENT->_atexit;
  lastp = &_GLOBAL_REENT->_atexit;
  while (p)
    {
#ifdef _REENT_SMALL
      args = p->_on_exit_args_ptr;
#else
      args = &p->_on_exit_args;
#endif
      for (n = p->_ind - 1; n >= 0; n--)
	{
	  int ind;

	  i = 1 << n;

	  /* Skip functions not from this dso.  */
	  if (d && (!args || args->_dso_handle[n] != d))
	    continue;

	  /* Remove the function now to protect against the
	     function calling exit recursively.  */
	  fn = p->_fns[n];
	  if (n == p->_ind - 1)
	    p->_ind--;
	  else
	    p->_fns[n] = NULL;

	  /* Skip functions that have already been called.  */
	  if (!fn)
	    continue;

	  ind = p->_ind;

	  /* Call the function.  */
	  if (!args || (args->_fntypes & i) == 0)
	    fn ();
	  else if ((args->_is_cxa & i) == 0)
	    (*((void (*)(int, _PTR)) fn))(code, args->_fnargs[n]);
	  else
	    (*((void (*)(_PTR)) fn))(args->_fnargs[n]);

	  /* The function we called call atexit and registered another
	     function (or functions).  Call these new functions before
	     continuing with the already registered functions.  */
	  if (ind != p->_ind || *lastp != p)
	    goto restart;
	}

#ifndef _ATEXIT_DYNAMIC_ALLOC
      break;
#else
      /* Move to the next block.  Free empty blocks except the last one,
	 which is part of _GLOBAL_REENT.  */
      if (p->_ind == 0 && p->_next)
	{
	  /* Remove empty block from the list.  */
	  *lastp = p->_next;
#ifdef _REENT_SMALL
	  if (args)
	    free (args);
#endif
	  free (p);
	  p = *lastp;
	}
      else
	{
	  lastp = &p->_next;
	  p = p->_next;
	}
#endif
    }
}

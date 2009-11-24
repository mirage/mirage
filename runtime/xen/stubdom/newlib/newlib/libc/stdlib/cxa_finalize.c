/*
 * Implementation if __cxa_finalize.
 */


#include <stdlib.h>
#include <reent.h>
#include "atexit.h"

/*
 * Call registered exit handlers.  If D is null then all handlers are called,
 * otherwise only the handlers from that DSO are called.
 */

void 
_DEFUN (__cxa_finalize, (d),
	void * d)
{
  __call_exitprocs (0, d);
}

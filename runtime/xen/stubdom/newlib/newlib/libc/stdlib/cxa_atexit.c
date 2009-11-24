/*
 * Implementation of __cxa_atexit.
 */

#include <stddef.h>
#include <stdlib.h>
#include <reent.h>
#include <sys/lock.h>
#include "atexit.h"

/*
 * Register a function to be performed at exit or DSO unload.
 */

int
_DEFUN (__cxa_atexit,
	(fn, arg, d),
	void (*fn) (void *) _AND
	void *arg _AND
	void *d)
{
  return __register_exitproc (__et_cxa, (void (*)(void)) fn, arg, d);
}

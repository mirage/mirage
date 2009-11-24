/*
 * Copyright (c) 1990 Regents of the University of California.
 * All rights reserved.
 *
 * %sccs.include.redist.c%
 */

/*
FUNCTION
<<atexit>>---request execution of functions at program exit

INDEX
	atexit

ANSI_SYNOPSIS
	#include <stdlib.h>
	int atexit (void (*<[function]>)(void));

TRAD_SYNOPSIS
	#include <stdlib.h>
	int atexit ((<[function]>)
	  void (*<[function]>)();

DESCRIPTION
You can use <<atexit>> to enroll functions in a list of functions that
will be called when your program terminates normally.  The argument is
a pointer to a user-defined function (which must not require arguments and
must not return a result).

The functions are kept in a LIFO stack; that is, the last function
enrolled by <<atexit>> will be the first to execute when your program
exits.

There is no built-in limit to the number of functions you can enroll
in this list; however, after every group of 32 functions is enrolled,
<<atexit>> will call <<malloc>> to get space for the next part of the
list.   The initial list of 32 functions is statically allocated, so
you can always count on at least that many slots available.

RETURNS
<<atexit>> returns <<0>> if it succeeds in enrolling your function,
<<-1>> if it fails (possible only if no space was available for
<<malloc>> to extend the list of functions).

PORTABILITY
<<atexit>> is required by the ANSI standard, which also specifies that
implementations must support enrolling at least 32 functions.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <stdlib.h>
#include "atexit.h"

/*
 * Register a function to be performed at exit.
 */

int
_DEFUN (atexit,
	(fn),
	_VOID _EXFUN ((*fn), (_VOID)))
{
  return __register_exitproc (__et_atexit, fn, NULL, NULL);
}

/*
 * Copyright (c) 1990 Regents of the University of California.
 * All rights reserved.
 *
 * %sccs.include.redist.c%
 *
 * This function is a modified version of atexit.c
 */

/*
FUNCTION
<<on_exit>>---request execution of function with argument at program exit

INDEX
	on_exit

ANSI_SYNOPSIS
	#include <stdlib.h>
	int on_exit (void (*<[function]>)(int, void *), void *<[arg]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	int on_exit ((<[function]>, <[arg]>)
	  void (*<[function]>)(int, void *);
	  void *<[arg]>;

DESCRIPTION
You can use <<on_exit>> to enroll functions in a list of functions that
will be called when your program terminates normally.  The argument is
a pointer to a user-defined function which takes two arguments.  The
first is the status code passed to exit and the second argument is of type
pointer to void.  The function must not return a result.  The value
of <[arg]> is registered and passed as the argument to <[function]>.

The functions are kept in a LIFO stack; that is, the last function
enrolled by <<atexit>> or <<on_exit>> will be the first to execute when 
your program exits.  You can intermix functions using <<atexit>> and
<<on_exit>>.

There is no built-in limit to the number of functions you can enroll
in this list; however, after every group of 32 functions is enrolled,
<<atexit>>/<<on_exit>> will call <<malloc>> to get space for the next part 
of the list.   The initial list of 32 functions is statically allocated, so
you can always count on at least that many slots available.

RETURNS
<<on_exit>> returns <<0>> if it succeeds in enrolling your function,
<<-1>> if it fails (possible only if no space was available for
<<malloc>> to extend the list of functions).

PORTABILITY
<<on_exit>> is a non-standard glibc extension

Supporting OS subroutines required: None
*/

#include <stddef.h>
#include <stdlib.h>
#include "atexit.h"

/*
 * Register a function to be performed at exit.
 */

int
_DEFUN (on_exit,
	(fn, arg),
	_VOID _EXFUN ((*fn), (int, _PTR)) _AND
        _PTR arg)
{
  return __register_exitproc (__et_onexit, (void (*)(void)) fn, arg, NULL);
}

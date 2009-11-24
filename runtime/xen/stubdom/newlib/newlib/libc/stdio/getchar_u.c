/*
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
FUNCTION
<<getchar_unlocked>>---non-thread-safe version of getchar (macro)

INDEX
	getchar_unlocked
INDEX
	_getchar_unlocked_r

POSIX_SYNOPSIS
	#include <stdio.h>
	int getchar_unlocked();

	#include <stdio.h>
	int _getchar_unlocked_r(struct _reent *<[ptr]>);

DESCRIPTION
<<getchar_unlocked>> is a non-thread-safe version of <<getchar>>
declared in <<stdio.h>>.  <<getchar_unlocked>> may only safely be used
within a scope protected by flockfile() (or ftrylockfile()) and
funlockfile().  These functions may safely be used in a multi-threaded
program if and only if they are called while the invoking thread owns
the ( FILE *) object, as is the case after a successful call to the
flockfile() or ftrylockfile() functions.  If threads are disabled,
then <<getchar_unlocked>> is equivalent to <<getchar>>.

The <<_getchar_unlocked_r>> function is simply the reentrant version of
<<getchar_unlocked>> which passes an addtional reentrancy structure pointer
argument: <[ptr]>.

RETURNS
See <<getchar>>.

PORTABILITY
POSIX 1003.1 requires <<getchar_unlocked>>.  <<getchar_unlocked>> may
be implemented as a macro.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.  */

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

/*
 * A subroutine version of the macro getchar_unlocked.
 */

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>

#undef getchar_unlocked

int
_DEFUN(_getchar_unlocked_r, (ptr),
       struct _reent *ptr)
{
  return _getc_unlocked_r (ptr, _stdin_r (ptr));
}

#ifndef _REENT_ONLY

int
_DEFUN_VOID(getchar_unlocked)
{
  /* CHECK_INIT is called (eventually) by __srefill_r.  */

  return _getc_unlocked_r (_REENT, _stdin_r (_REENT));
}

#endif

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
<<getc_unlocked>>---non-thread-safe version of getc (macro)

INDEX
	getc_unlocked
INDEX
	_getc_unlocked_r

POSIX_SYNOPSIS
	#include <stdio.h>
	int getc_unlocked(FILE *<[fp]>);

	#include <stdio.h>
	int _getc_unlocked_r(FILE *<[fp]>);

DESCRIPTION
<<getc_unlocked>> is a non-thread-safe version of <<getc>> declared in
<<stdio.h>>.  <<getc_unlocked>> may only safely be used within a scope
protected by flockfile() (or ftrylockfile()) and funlockfile().  These
functions may safely be used in a multi-threaded program if and only
if they are called while the invoking thread owns the ( FILE *)
object, as is the case after a successful call to the flockfile() or
ftrylockfile() functions.  If threads are disabled, then
<<getc_unlocked>> is equivalent to <<getc>>.

The <<_getc_unlocked_r>> function is simply the reentrant version of
<<get_unlocked>> which passes an additional reentrancy structure pointer
argument: <[ptr]>.

RETURNS
See <<getc>>.

PORTABILITY
POSIX 1003.1 requires <<getc_unlocked>>.  <<getc_unlocked>> may be
implemented as a macro, so arguments should not have side-effects.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.  */

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <stdio.h>

/*
 * A subroutine version of the macro getc_unlocked.
 */

#undef getc_unlocked

int
_DEFUN(_getc_unlocked_r, (ptr, fp),
       struct _reent *ptr _AND
       register FILE *fp)
{
  /* CHECK_INIT is called (eventually) by __srefill_r.  */

  return __sgetc_r (ptr, fp);
}

#ifndef _REENT_ONLY

int
_DEFUN(getc_unlocked, (fp),
       register FILE *fp)
{
  return __sgetc_r (_REENT, fp);
}

#endif /* !_REENT_ONLY */

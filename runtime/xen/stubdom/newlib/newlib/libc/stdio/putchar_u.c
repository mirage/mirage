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
<<putchar_unlocked>>---non-thread-safe version of putchar (macro)

INDEX
	putchar_unlocked

POSIX_SYNOPSIS
	#include <stdio.h>
	int putchar_unlocked(int <[ch]>);

DESCRIPTION
<<putchar_unlocked>> is a non-thread-safe version of <<putchar>>
declared in <<stdio.h>>.  <<putchar_unlocked>> may only safely be used
within a scope protected by flockfile() (or ftrylockfile()) and
funlockfile().  These functions may safely be used in a multi-threaded
program if and only if they are called while the invoking thread owns
the ( FILE *) object, as is the case after a successful call to the
flockfile() or ftrylockfile() functions.  If threads are disabled,
then <<putchar_unlocked>> is equivalent to <<putchar>>.

RETURNS
See <<putchar>>.

PORTABILITY
POSIX 1003.1 requires <<putchar_unlocked>>.  <<putchar_unlocked>> may
be implemented as a macro.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.  */

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

/*
 * A subroutine version of the macro putchar_unlocked.
 */

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>

#undef putchar_unlocked

int
_DEFUN(_putchar_unlocked_r, (ptr, c),
       struct _reent *ptr _AND
       int c)
{
  return putc_unlocked (c, _stdout_r (ptr));
}

#ifndef _REENT_ONLY

int
_DEFUN(putchar_unlocked, (c),
       int c)
{
  /* CHECK_INIT is (eventually) called by __swbuf.  */

  return _putchar_unlocked_r (_REENT, c);
}

#endif

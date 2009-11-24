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
<<putc_unlocked>>---non-thread-safe version of putc (macro)

INDEX
	putc_unlocked
INDEX
	_putc_unlocked_r

POSIX_SYNOPSIS
	#include <stdio.h>
	int putc_unlocked(int <[ch]>, FILE *<[fp]>);

	#include <stdio.h>
	int _putc_unlocked_r(struct _reent *<[ptr]>, int <[ch]>, FILE *<[fp]>);

DESCRIPTION
<<putc_unlocked>> is a non-thread-safe version of <<putc>> declared in
<<stdio.h>>.  <<putc_unlocked>> may only safely be used within a scope
protected by flockfile() (or ftrylockfile()) and funlockfile().  These
functions may safely be used in a multi-threaded program if and only
if they are called while the invoking thread owns the ( FILE *)
object, as is the case after a successful call to the flockfile() or
ftrylockfile() functions.  If threads are disabled, then
<<putc_unlocked>> is equivalent to <<putc>>.

The function <<_putc_unlocked_r>> is simply the reentrant version of
<<putc_unlocked>> that takes an additional reentrant structure pointer
argument: <[ptr]>.

RETURNS
See <<putc>>.

PORTABILITY
POSIX 1003.1 requires <<putc_unlocked>>.  <<putc_unlocked>> may be
implemented as a macro, so arguments should not have side-effects.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <stdio.h>

/*
 * A subroutine version of the macro putc_unlocked.
 */

#undef putc_unlocked

int
_DEFUN(_putc_unlocked_r, (ptr, c, fp),
       struct _reent *ptr _AND
       int c _AND
       register FILE *fp)
{
  /* CHECK_INIT is (eventually) called by __swbuf.  */

  return __sputc_r (ptr, c, fp);
}

#ifndef _REENT_ONLY
int
_DEFUN(putc_unlocked, (c, fp),
       int c _AND
       register FILE *fp)
{
  /* CHECK_INIT is (eventually) called by __swbuf.  */

  return __sputc_r (_REENT, c, fp);
}
#endif /* !_REENT_ONLY */

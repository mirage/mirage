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
<<getchar>>---read a character (macro)

INDEX
	getchar
INDEX
	_getchar_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int getchar(void);

	int _getchar_r(struct _reent *<[reent]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int getchar();

	int _getchar_r(<[reent]>)
	char * <[reent]>;

DESCRIPTION
<<getchar>> is a macro, defined in <<stdio.h>>.  You can use <<getchar>>
to get the next single character from the standard input stream.
As a side effect, <<getchar>> advances the standard input's
current position indicator.

The alternate function <<_getchar_r>> is a reentrant version.  The
extra argument <[reent]> is a pointer to a reentrancy structure.


RETURNS
The next character (read as an <<unsigned char>>, and cast to
<<int>>), unless there is no more data, or the host system reports a
read error; in either of these situations, <<getchar>> returns <<EOF>>.

You can distinguish the two situations that cause an <<EOF>> result by
using `<<ferror(stdin)>>' and `<<feof(stdin)>>'.

PORTABILITY
ANSI C requires <<getchar>>; it suggests, but does not require, that
<<getchar>> be implemented as a macro.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

/*
 * A subroutine version of the macro getchar.
 */

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include "local.h"

#undef getchar

int
_DEFUN(_getchar_r, (reent),
       struct _reent *reent)
{
  _REENT_SMALL_CHECK_INIT (reent);
  return _getc_r (reent, _stdin_r (reent));
}

#ifndef _REENT_ONLY

int
_DEFUN_VOID(getchar)
{
  /* CHECK_INIT is called (eventually) by __srefill_r.  */
  _REENT_SMALL_CHECK_INIT (_REENT);
  return _getc_r (_REENT, _stdin_r (_REENT));
}

#endif

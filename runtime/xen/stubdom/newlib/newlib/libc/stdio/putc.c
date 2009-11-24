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
<<putc>>---write a character (macro)

INDEX
	putc
INDEX
	_putc_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int putc(int <[ch]>, FILE *<[fp]>);

	#include <stdio.h>
	int _putc_r(struct _reent *<[ptr]>, int <[ch]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int putc(<[ch]>, <[fp]>)
	int <[ch]>;
	FILE *<[fp]>;

	#include <stdio.h>
	int _putc_r(<[ptr]>, <[ch]>, <[fp]>)
	struct _reent *<[ptr]>;
	int <[ch]>;
	FILE *<[fp]>;

DESCRIPTION
<<putc>> is a macro, defined in <<stdio.h>>.  <<putc>>
writes the argument <[ch]> to the file or stream identified by
<[fp]>, after converting it from an <<int>> to an <<unsigned char>>.

If the file was opened with append mode (or if the stream cannot
support positioning), then the new character goes at the end of the
file or stream.  Otherwise, the new character is written at the
current value of the position indicator, and the position indicator
advances by one.

For a subroutine version of this macro, see <<fputc>>.

The <<_putc_r>> function is simply the reentrant version of
<<putc>> that takes an additional reentrant structure argument: <[ptr]>.

RETURNS
If successful, <<putc>> returns its argument <[ch]>.  If an error
intervenes, the result is <<EOF>>.  You can use `<<ferror(<[fp]>)>>' to
query for errors.

PORTABILITY
ANSI C requires <<putc>>; it suggests, but does not require, that
<<putc>> be implemented as a macro.  The standard explicitly permits
macro implementations of <<putc>> to use the <[fp]> argument more than once;
therefore, in a portable program, you should not use an expression
with side effects as this argument.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <stdio.h>
#include "local.h"

/*
 * A subroutine version of the macro putc.
 */

#undef putc

int
_DEFUN(_putc_r, (ptr, c, fp),
       struct _reent *ptr _AND
       int c _AND
       register FILE *fp)
{
  int result;
  CHECK_INIT (ptr, fp);
  _flockfile (fp);
  result = __sputc_r (ptr, c, fp);
  _funlockfile (fp);
  return result;
}

#ifndef _REENT_ONLY
int
_DEFUN(putc, (c, fp),
       int c _AND
       register FILE *fp)
{
#if !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__)
  int result;
  CHECK_INIT (_REENT, fp);
  _flockfile (fp);
  result = __sputc_r (_REENT, c, fp);
  _funlockfile (fp);
  return result;
#else
  return _putc_r (_REENT, c, fp);
#endif
}
#endif /* !_REENT_ONLY */


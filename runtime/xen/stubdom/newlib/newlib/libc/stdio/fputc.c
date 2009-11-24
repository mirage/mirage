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
<<fputc>>---write a character on a stream or file

INDEX
	fputc
INDEX
	_fputc_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int fputc(int <[ch]>, FILE *<[fp]>);

	#include <stdio.h>
	int _fputc_r(struct _rent *<[ptr]>, int <[ch]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int fputc(<[ch]>, <[fp]>)
	int <[ch]>;
	FILE *<[fp]>;

	#include <stdio.h>
	int _fputc_r(<[ptr]>, <[ch]>, <[fp]>)
	struct _reent *<[ptr]>;
	int <[ch]>;
	FILE *<[fp]>;

DESCRIPTION
<<fputc>> converts the argument <[ch]> from an <<int>> to an
<<unsigned char>>, then writes it to the file or stream identified by
<[fp]>.

If the file was opened with append mode (or if the stream cannot
support positioning), then the new character goes at the end of the
file or stream.  Otherwise, the new character is written at the
current value of the position indicator, and the position indicator
oadvances by one.

For a macro version of this function, see <<putc>>.

The <<_fputc_r>> function is simply a reentrant version of <<fputc>>
that takes an additional reentrant structure argument: <[ptr]>.

RETURNS
If successful, <<fputc>> returns its argument <[ch]>.  If an error
intervenes, the result is <<EOF>>.  You can use `<<ferror(<[fp]>)>>' to
query for errors.

PORTABILITY
<<fputc>> is required by ANSI C.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <stdio.h>
#include "local.h"

int
_DEFUN(_fputc_r, (ptr, ch, file),
       struct _reent *ptr _AND
       int ch _AND
       FILE * file)
{
  int result;
  CHECK_INIT(ptr, file);
   _flockfile (file);
  result = _putc_r (ptr, ch, file);
  _funlockfile (file);
  return result;
}

#ifndef _REENT_ONLY
int
_DEFUN(fputc, (ch, file),
       int ch _AND
       FILE * file)
{
#if !defined(__OPTIMIZE_SIZE__) && !defined(PREFER_SIZE_OVER_SPEED)
  int result;
  CHECK_INIT(_REENT, file);
   _flockfile (file);
  result = _putc_r (_REENT, ch, file);
  _funlockfile (file);
  return result;
#else
  return _fputc_r (_REENT, ch, file);
#endif
}
#endif /* !_REENT_ONLY */

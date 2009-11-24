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
<<fgetc>>---get a character from a file or stream

INDEX
	fgetc
INDEX
	_fgetc_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int fgetc(FILE *<[fp]>);

	#include <stdio.h>
	int _fgetc_r(struct _reent *<[ptr]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int fgetc(<[fp]>)
	FILE *<[fp]>;

	#include <stdio.h>
	int _fgetc_r(<[ptr]>, <[fp]>)
	struct _reent *<[ptr]>;
	FILE *<[fp]>;

DESCRIPTION
Use <<fgetc>> to get the next single character from the file or stream
identified by <[fp]>.  As a side effect, <<fgetc>> advances the file's
current position indicator.

For a macro version of this function, see <<getc>>.

The function <<_fgetc_r>> is simply a reentrant version of
<<fgetc>> that is passed the additional reentrant structure
pointer argument: <[ptr]>.

RETURNS
The next character (read as an <<unsigned char>>, and cast to
<<int>>), unless there is no more data, or the host system reports a
read error; in either of these situations, <<fgetc>> returns <<EOF>>.

You can distinguish the two situations that cause an <<EOF>> result by
using the <<ferror>> and <<feof>> functions.

PORTABILITY
ANSI C requires <<fgetc>>.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <stdio.h>
#include "local.h"

int
_DEFUN(_fgetc_r, (ptr, fp),
       struct _reent * ptr _AND
       FILE * fp)
{
  int result;
  CHECK_INIT(ptr, fp);
  _flockfile (fp);
  result = __sgetc_r (ptr, fp);
  _funlockfile (fp);
  return result;
}

#ifndef _REENT_ONLY

int
_DEFUN(fgetc, (fp),
       FILE * fp)
{
#if !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__)
  int result;
  CHECK_INIT(_REENT, fp);
  _flockfile (fp);
  result = __sgetc_r (_REENT, fp);
  _funlockfile (fp);
  return result;
#else
  return _fgetc_r (_REENT, fp);
#endif
}

#endif /* !_REENT_ONLY */


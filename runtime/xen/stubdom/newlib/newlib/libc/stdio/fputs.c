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
<<fputs>>---write a character string in a file or stream

INDEX
	fputs
INDEX
	_fputs_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int fputs(const char *<[s]>, FILE *<[fp]>);

	#include <stdio.h>
	int _fputs_r(struct _reent *<[ptr]>, const char *<[s]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int fputs(<[s]>, <[fp]>)
	char *<[s]>;
	FILE *<[fp]>;

	#include <stdio.h>
	int _fputs_r(<[ptr]>, <[s]>, <[fp]>)
	struct _reent *<[ptr]>;
	char *<[s]>;
	FILE *<[fp]>;

DESCRIPTION
<<fputs>> writes the string at <[s]> (but without the trailing null)
to the file or stream identified by <[fp]>.

<<_fputs_r>> is simply the reentrant version of <<fputs>> that takes
an additional reentrant struct pointer argument: <[ptr]>.

RETURNS
If successful, the result is <<0>>; otherwise, the result is <<EOF>>.

PORTABILITY
ANSI C requires <<fputs>>, but does not specify that the result on
success must be <<0>>; any non-negative value is permitted.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <stdio.h>
#include <string.h>
#include "fvwrite.h"
#include "local.h"

/*
 * Write the given string to the given file.
 */

int
_DEFUN(_fputs_r, (ptr, s, fp),
       struct _reent * ptr _AND
       char _CONST * s _AND
       FILE * fp)
{
  int result;
  struct __suio uio;
  struct __siov iov;

  iov.iov_base = s;
  iov.iov_len = uio.uio_resid = strlen (s);
  uio.uio_iov = &iov;
  uio.uio_iovcnt = 1;

  CHECK_INIT(ptr, fp);

  _flockfile (fp);
  result = __sfvwrite_r (ptr, fp, &uio);
  _funlockfile (fp);
  return result;
}

#ifndef _REENT_ONLY
int
_DEFUN(fputs, (s, fp),
       char _CONST * s _AND
       FILE * fp)
{
  return _fputs_r (_REENT, s, fp);
}
#endif /* !_REENT_ONLY */

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
<<fileno>>---return file descriptor associated with stream

INDEX
	fileno

ANSI_SYNOPSIS
	#include <stdio.h>
	int fileno(FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int fileno(<[fp]>)
	FILE *<[fp]>;

DESCRIPTION
You can use <<fileno>> to return the file descriptor identified by <[fp]>.

RETURNS
<<fileno>> returns a non-negative integer when successful.
If <[fp]> is not an open stream, <<fileno>> returns -1.

PORTABILITY
<<fileno>> is not part of ANSI C.
POSIX requires <<fileno>>.

Supporting OS subroutines required: none.
*/

#include <_ansi.h>
#include <stdio.h>
#include "local.h"

int
_DEFUN(fileno, (f),
       FILE * f)
{
  int result;
  CHECK_INIT (_REENT, f);
  _flockfile (f);
  result = __sfileno (f);
  _funlockfile (f);
  return result;
}

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
<<clearerr>>---clear file or stream error indicator

INDEX
	clearerr

ANSI_SYNOPSIS
	#include <stdio.h>
	void clearerr(FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	void clearerr(<[fp]>)
	FILE *<[fp]>;

DESCRIPTION
The <<stdio>> functions maintain an error indicator with each file
pointer <[fp]>, to record whether any read or write errors have
occurred on the associated file or stream.  Similarly, it maintains an
end-of-file indicator to record whether there is no more data in the
file.

Use <<clearerr>> to reset both of these indicators.

See <<ferror>> and <<feof>> to query the two indicators.


RETURNS
<<clearerr>> does not return a result.

PORTABILITY
ANSI C requires <<clearerr>>.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <stdio.h>
#include "local.h"

/* A subroutine version of the macro clearerr.  */

#undef	clearerr

_VOID
_DEFUN(clearerr, (fp),
       FILE * fp)
{
  CHECK_INIT(_REENT, fp);
  _flockfile (fp);
  __sclearerr (fp);
  _funlockfile (fp);
}

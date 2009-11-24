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
<<ferror>>---test whether read/write error has occurred

INDEX
	ferror

ANSI_SYNOPSIS
	#include <stdio.h>
	int ferror(FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int ferror(<[fp]>)
	FILE *<[fp]>;

DESCRIPTION
The <<stdio>> functions maintain an error indicator with each file
pointer <[fp]>, to record whether any read or write errors have
occurred on the associated file or stream.
Use <<ferror>> to query this indicator.

See <<clearerr>> to reset the error indicator.

RETURNS
<<ferror>> returns <<0>> if no errors have occurred; it returns a
nonzero value otherwise.

PORTABILITY
ANSI C requires <<ferror>>.

No supporting OS subroutines are required.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <stdio.h>
#include "local.h"

/* A subroutine version of the macro ferror.  */

#undef ferror

int
_DEFUN(ferror, (fp),
       FILE * fp)
{
  int result;
  CHECK_INIT(_REENT, fp);
  _flockfile (fp);
  result = __sferror (fp);
  _funlockfile (fp);
  return result;
}

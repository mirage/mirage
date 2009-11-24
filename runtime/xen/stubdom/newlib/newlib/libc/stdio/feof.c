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
<<feof>>---test for end of file

INDEX
	feof

ANSI_SYNOPSIS
	#include <stdio.h>
	int feof(FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int feof(<[fp]>)
	FILE *<[fp]>;

DESCRIPTION
<<feof>> tests whether or not the end of the file identified by <[fp]>
has been reached.

RETURNS
<<feof>> returns <<0>> if the end of file has not yet been reached; if
at end of file, the result is nonzero.

PORTABILITY
<<feof>> is required by ANSI C.

No supporting OS subroutines are required.
*/

#include <stdio.h>
#include "local.h"

/* A subroutine version of the macro feof.  */

#undef feof

int 
_DEFUN(feof, (fp),
       FILE * fp)
{
  int result;
  CHECK_INIT(_REENT, fp);
  _flockfile (fp);
  result = __sfeof (fp);
  _funlockfile (fp);
  return result;
}

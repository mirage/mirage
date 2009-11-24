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
<<putw>>---write a word (int)

INDEX
	putw

ANSI_SYNOPSIS
	#include <stdio.h>
	int putw(int <[w]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int putw(<w>, <[fp]>)
	int <w>;
	FILE *<[fp]>;

DESCRIPTION
<<putw>> is a function, defined in <<stdio.h>>.  You can use <<putw>>
to write a word to the file or stream identified by <[fp]>.  As a side
effect, <<putw>> advances the file's current position indicator.

RETURNS
Zero on success, <<EOF>> on failure.

PORTABILITY
<<putw>> is a remnant of K&R C; it is not part of any ISO C Standard.
<<fwrite>> should be used instead.  In fact, this implementation of
<<putw>> is based upon <<fwrite>>.

Supporting OS subroutines required: <<fwrite>>.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <stdio.h>

int
_DEFUN(putw, (w, fp),
       int w _AND
       register FILE *fp)
{
  if (fwrite ((_CONST char*)&w, sizeof (w), 1, fp) != 1)
    return EOF;
  return 0;
}

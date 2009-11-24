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
<<getw>>---read a word (int)

INDEX
	getw

ANSI_SYNOPSIS
	#include <stdio.h>
	int getw(FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int getw(<[fp]>)
	FILE *<[fp]>;

DESCRIPTION
<<getw>> is a function, defined in <<stdio.h>>.  You can use <<getw>>
to get the next word from the file or stream identified by <[fp]>.  As
a side effect, <<getw>> advances the file's current position
indicator.

RETURNS
The next word (read as an <<int>>), unless there is no more
data or the host system reports a read error; in either of these
situations, <<getw>> returns <<EOF>>.  Since <<EOF>> is a valid
<<int>>, you must use <<ferror>> or <<feof>> to distinguish these
situations.

PORTABILITY
<<getw>> is a remnant of K&R C; it is not part of any ISO C Standard.
<<fread>> should be used instead.  In fact, this implementation of
<<getw>> is based upon <<fread>>.

Supporting OS subroutines required: <<fread>>.  */

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <stdio.h>

int
_DEFUN(getw, (fp),
       register FILE *fp)
{
  int result;
  if (fread ((char*)&result, sizeof (result), 1, fp) != 1)
    return EOF;
  return result;
}

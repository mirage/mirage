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
Modified copy of setbuf.c to support setlinebuf function
defined as part of BSD.
Modifications by Gareth Pearce, 2001.
*/

/*
FUNCTION
<<setlinebuf>>---specify line buffering for a file or stream

INDEX
	setlinebuf

ANSI_SYNOPSIS
	#include <stdio.h>
	void setlinebuf(FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	void setlinebuf(<[fp]>)
	FILE *<[fp]>;

DESCRIPTION
<<setlinebuf>> specifies that output to the file or stream identified by
<[fp]> should be line buffered.  This causes the file or stream to pass
on output to the host system at every newline, as well as when the
buffer is full, or when an input operation intervenes.

WARNINGS
You may only use <<setlinebuf>> before performing any file operation
other than opening the file.

RETURNS
<<setlinebuf>> returns as per setvbuf.

PORTABILITY
This function comes from BSD not ANSI or POSIX.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <stdio.h>
#include "local.h"

int
_DEFUN(setlinebuf, (fp),
       FILE * fp)
{
  return (setvbuf (fp, (char *) NULL, _IOLBF, (size_t) 0));
}

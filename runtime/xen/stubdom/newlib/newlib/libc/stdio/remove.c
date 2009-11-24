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
<<remove>>---delete a file's name

INDEX
	remove

ANSI_SYNOPSIS
	#include <stdio.h>
	int remove(char *<[filename]>);

	int _remove_r(struct _reent *<[reent]>, char *<[filename]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int remove(<[filename]>)
	char *<[filename]>;

	int _remove_r(<[reent]>, <[filename]>)
	struct _reent *<[reent]>;
	char *<[filename]>;

DESCRIPTION
Use <<remove>> to dissolve the association between a particular
filename (the string at <[filename]>) and the file it represents.
After calling <<remove>> with a particular filename, you will no
longer be able to open the file by that name.

In this implementation, you may use <<remove>> on an open file without
error; existing file descriptors for the file will continue to access
the file's data until the program using them closes the file.

The alternate function <<_remove_r>> is a reentrant version.  The
extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
<<remove>> returns <<0>> if it succeeds, <<-1>> if it fails.

PORTABILITY
ANSI C requires <<remove>>, but only specifies that the result on
failure be nonzero.  The behavior of <<remove>> when you call it on an
open file may vary among implementations.

Supporting OS subroutine required: <<unlink>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>

int
_DEFUN(_remove_r, (ptr, filename),
       struct _reent *ptr _AND
       _CONST char *filename)
{
  if (_unlink_r (ptr, filename) == -1)
    return -1;

  return 0;
}

#ifndef _REENT_ONLY

int
_DEFUN(remove, (filename),
       _CONST char *filename)
{
  return _remove_r (_REENT, filename);
}

#endif

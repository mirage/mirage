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
<<fopen>>---open a file

INDEX
	fopen
INDEX
	_fopen_r

ANSI_SYNOPSIS
	#include <stdio.h>
	FILE *fopen(const char *<[file]>, const char *<[mode]>);

	FILE *_fopen_r(struct _reent *<[reent]>, 
                       const char *<[file]>, const char *<[mode]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	FILE *fopen(<[file]>, <[mode]>)
	char *<[file]>;
	char *<[mode]>;

	FILE *_fopen_r(<[reent]>, <[file]>, <[mode]>)
	struct _reent *<[reent]>;
	char *<[file]>;
	char *<[mode]>;

DESCRIPTION
<<fopen>> initializes the data structures needed to read or write a
file.  Specify the file's name as the string at <[file]>, and the kind
of access you need to the file with the string at <[mode]>.

The alternate function <<_fopen_r>> is a reentrant version.
The extra argument <[reent]> is a pointer to a reentrancy structure.

Three fundamental kinds of access are available: read, write, and append.
<<*<[mode]>>> must begin with one of the three characters `<<r>>',
`<<w>>', or `<<a>>', to select one of these:

o+
o r
Open the file for reading; the operation will fail if the file does
not exist, or if the host system does not permit you to read it.

o w
Open the file for writing @emph{from the beginning} of the file:
effectively, this always creates a new file.  If the file whose name you
specified already existed, its old contents are discarded.

o a
Open the file for appending data, that is writing from the end of
file.  When you open a file this way, all data always goes to the
current end of file; you cannot change this using <<fseek>>.
o-

Some host systems distinguish between ``binary'' and ``text'' files.
Such systems may perform data transformations on data written to, or
read from, files opened as ``text''.
If your system is one of these, then you can append a `<<b>>' to any
of the three modes above, to specify that you are opening the file as
a binary file (the default is to open the file as a text file).

`<<rb>>', then, means ``read binary''; `<<wb>>', ``write binary''; and
`<<ab>>', ``append binary''.

To make C programs more portable, the `<<b>>' is accepted on all
systems, whether or not it makes a difference.

Finally, you might need to both read and write from the same file.
You can also append a `<<+>>' to any of the three modes, to permit
this.  (If you want to append both `<<b>>' and `<<+>>', you can do it
in either order: for example, <<"rb+">> means the same thing as
<<"r+b">> when used as a mode string.)

Use <<"r+">> (or <<"rb+">>) to permit reading and writing anywhere in
an existing file, without discarding any data; <<"w+">> (or <<"wb+">>)
to create a new file (or begin by discarding all data from an old one)
that permits reading and writing anywhere in it; and <<"a+">> (or
<<"ab+">>) to permit reading anywhere in an existing file, but writing
only at the end.

RETURNS
<<fopen>> returns a file pointer which you can use for other file
operations, unless the file you requested could not be opened; in that
situation, the result is <<NULL>>.  If the reason for failure was an
invalid string at <[mode]>, <<errno>> is set to <<EINVAL>>.

PORTABILITY
<<fopen>> is required by ANSI C.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<open>>, <<read>>, <<sbrk>>, <<write>>.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <errno.h>
#include <sys/lock.h>
#ifdef __CYGWIN__
#include <fcntl.h>
#endif
#include "local.h"

FILE *
_DEFUN(_fopen_r, (ptr, file, mode),
       struct _reent *ptr _AND
       _CONST char *file _AND
       _CONST char *mode)
{
  register FILE *fp;
  register int f;
  int flags, oflags;

  if ((flags = __sflags (ptr, mode, &oflags)) == 0)
    return NULL;
  if ((fp = __sfp (ptr)) == NULL)
    return NULL;

  if ((f = _open_r (ptr, file, oflags, 0666)) < 0)
    {
      __sfp_lock_acquire (); 
      fp->_flags = 0;		/* release */
#ifndef __SINGLE_THREAD__
      __lock_close_recursive (fp->_lock);
#endif
      __sfp_lock_release (); 
      return NULL;
    }

  _flockfile (fp);

  fp->_file = f;
  fp->_flags = flags;
  fp->_cookie = (_PTR) fp;
  fp->_read = __sread;
  fp->_write = __swrite;
  fp->_seek = __sseek;
  fp->_close = __sclose;

  if (fp->_flags & __SAPP)
    _fseek_r (ptr, fp, 0, SEEK_END);

#ifdef __SCLE
  if (__stextmode (fp->_file))
    fp->_flags |= __SCLE;
#endif

  _funlockfile (fp);
  return fp;
}

#ifndef _REENT_ONLY

FILE *
_DEFUN(fopen, (file, mode),
       _CONST char *file _AND
       _CONST char *mode)
{
  return _fopen_r (_REENT, file, mode);
}

#endif

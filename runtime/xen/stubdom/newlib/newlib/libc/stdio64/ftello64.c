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
<<ftello64>>---return position in a stream or file

INDEX
	ftello64
INDEX
	_ftello64_r

ANSI_SYNOPSIS
	#include <stdio.h>
	_off64_t ftello64(FILE *<[fp]>);
	_off64_t _ftello64_r(struct _reent *<[ptr]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	_off64_t ftello64(<[fp]>)
	FILE *<[fp]>;

	_off64_t _ftello64_r(<[ptr]>, <[fp]>)
	struct _reent *<[ptr]>;
	FILE *<[fp]>;

DESCRIPTION
Objects of type <<FILE>> can have a ``position'' that records how much
of the file your program has already read.  Many of the <<stdio>> functions
depend on this position, and many change it as a side effect.

The result of <<ftello64>> is the current position for a large file
identified by <[fp]>.  If you record this result, you can later
use it with <<fseeko64>> to return the file to this
position.  The difference between <<ftello>> and <<ftello64>> is that
<<ftello>> returns <<off_t>> and <<ftello64>> is designed to work
for large files (>2GB) and returns <<_off64_t>>.

In the current implementation, <<ftello64>> simply uses a character
count to represent the file position; this is the same number that
would be recorded by <<fgetpos64>>.

The function exists only if the __LARGE64_FILES flag is defined.
An error occurs if the <[fp]> was not opened via <<fopen64>>.

RETURNS
<<ftello64>> returns the file position, if possible.  If it cannot do
this, it returns <<-1>>.  Failure occurs on streams that do not support
positioning or not opened via <<fopen64>>; the global <<errno>> indicates
this condition with the value <<ESPIPE>>.

PORTABILITY
<<ftello64>> is a glibc extension.

No supporting OS subroutines are required.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

/*
 * ftello64: return current offset.
 */

#include <stdio.h>
#include <errno.h>

#include "local.h"

#ifdef __LARGE64_FILES

_off64_t
_DEFUN (_ftello64_r, (ptr, fp),
	struct _reent *ptr _AND
	register FILE * fp)
{
  _fpos64_t pos;

  /* Only do 64-bit tell on large file.  */
  if (!(fp->_flags & __SL64))
    return (_off64_t) _ftello_r (ptr, fp);

  /* Ensure stdio is set up.  */

  CHECK_INIT (ptr, fp);

  _flockfile(fp);

  if (fp->_seek64 == NULL)
    {
      ptr->_errno = ESPIPE;
      _funlockfile(fp);
      return -1L;
    }

  /* Find offset of underlying I/O object, then
     adjust for buffered bytes.  */
  _fflush_r (ptr, fp);           /* may adjust seek offset on append stream */
  if (fp->_flags & __SOFF)
    pos = fp->_offset;
  else
    {
      pos = fp->_seek64 (ptr, fp->_cookie, (_fpos64_t) 0, SEEK_CUR);
      if (pos == -1L)
        {
          _funlockfile(fp);
          return pos;
        }
    }
  if (fp->_flags & __SRD)
    {
      /*
       * Reading.  Any unread characters (including
       * those from ungetc) cause the position to be
       * smaller than that in the underlying object.
       */
      pos -= fp->_r;
      if (HASUB (fp))
	pos -= fp->_ur;
    }
  else if (fp->_flags & __SWR && fp->_p != NULL)
    {
      /*
       * Writing.  Any buffered characters cause the
       * position to be greater than that in the
       * underlying object.
       */
      pos += fp->_p - fp->_bf._base;
    }

  _funlockfile(fp);
  return pos;
}

#ifndef _REENT_ONLY

_off64_t
_DEFUN (ftello64, (fp),
	register FILE * fp)
{
  return _ftello64_r (_REENT, fp);
}

#endif /* !_REENT_ONLY */

#endif /* __LARGE64_FILES */

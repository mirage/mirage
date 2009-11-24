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
<<ftell>>, <<ftello>>---return position in a stream or file

INDEX
	ftell
INDEX
	ftello
INDEX
	_ftell_r
INDEX
	_ftello_r

ANSI_SYNOPSIS
	#include <stdio.h>
	long ftell(FILE *<[fp]>);
	off_t ftello(FILE *<[fp]>);
	long _ftell_r(struct _reent *<[ptr]>, FILE *<[fp]>);
	off_t _ftello_r(struct _reent *<[ptr]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	long ftell(<[fp]>)
	FILE *<[fp]>;

	off_t ftello(<[fp]>)
	FILE *<[fp]>;

	long _ftell_r(<[ptr]>, <[fp]>)
	struct _reent *<[ptr]>;
	FILE *<[fp]>;

	off_t _ftello_r(<[ptr]>, <[fp]>)
	struct _reent *<[ptr]>;
	FILE *<[fp]>;

DESCRIPTION
Objects of type <<FILE>> can have a ``position'' that records how much
of the file your program has already read.  Many of the <<stdio>> functions
depend on this position, and many change it as a side effect.

The result of <<ftell>>/<<ftello>> is the current position for a file
identified by <[fp]>.  If you record this result, you can later
use it with <<fseek>>/<<fseeko>> to return the file to this
position.  The difference between <<ftell>> and <<ftello>> is that
<<ftell>> returns <<long>> and <<ftello>> returns <<off_t>>.

In the current implementation, <<ftell>>/<<ftello>> simply uses a character
count to represent the file position; this is the same number that
would be recorded by <<fgetpos>>.

RETURNS
<<ftell>>/<<ftello>> return the file position, if possible.  If they cannot do
this, they return <<-1L>>.  Failure occurs on streams that do not support
positioning; the global <<errno>> indicates this condition with the
value <<ESPIPE>>.

PORTABILITY
<<ftell>> is required by the ANSI C standard, but the meaning of its
result (when successful) is not specified beyond requiring that it be
acceptable as an argument to <<fseek>>.  In particular, other
conforming C implementations may return a different result from
<<ftell>> than what <<fgetpos>> records.

<<ftello>> is defined by the Single Unix specification.

No supporting OS subroutines are required.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

/*
 * ftell: return current offset.
 */

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <errno.h>
#include "local.h"

long
_DEFUN(_ftell_r, (ptr, fp),
       struct _reent *ptr _AND
       register FILE * fp)
{
  _fpos_t pos;

  /* Ensure stdio is set up.  */

  CHECK_INIT (ptr, fp);

  _flockfile (fp);

  if (fp->_seek == NULL)
    {
      ptr->_errno = ESPIPE;
      _funlockfile (fp);
      return -1L;
    }

  /* Find offset of underlying I/O object, then
     adjust for buffered bytes.  */
  _fflush_r (ptr, fp);           /* may adjust seek offset on append stream */
  if (fp->_flags & __SOFF)
    pos = fp->_offset;
  else
    {
      pos = fp->_seek (ptr, fp->_cookie, (_fpos_t) 0, SEEK_CUR);
      if (pos == -1L)
        {
          _funlockfile (fp);
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
  else if ((fp->_flags & __SWR) && fp->_p != NULL)
    {
      /*
       * Writing.  Any buffered characters cause the
       * position to be greater than that in the
       * underlying object.
       */
      pos += fp->_p - fp->_bf._base;
    }

  _funlockfile (fp);
  if ((long)pos != pos)
    {
      pos = -1;
      ptr->_errno = EOVERFLOW;
    }
  return pos;
}

#ifndef _REENT_ONLY

long
_DEFUN(ftell, (fp),
       register FILE * fp)
{
  return _ftell_r (_REENT, fp);
}

#endif /* !_REENT_ONLY */

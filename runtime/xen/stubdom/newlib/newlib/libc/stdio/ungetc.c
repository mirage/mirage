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
<<ungetc>>---push data back into a stream

INDEX
	ungetc
INDEX
	_ungetc_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int ungetc(int <[c]>, FILE *<[stream]>);

	int _ungetc_r(struct _reent *<[reent]>, int <[c]>, FILE *<[stream]>);

DESCRIPTION
<<ungetc>> is used to return bytes back to <[stream]> to be read again.
If <[c]> is EOF, the stream is unchanged.  Otherwise, the unsigned
char <[c]> is put back on the stream, and subsequent reads will see
the bytes pushed back in reverse order.  Pushed byes are lost if the
stream is repositioned, such as by <<fseek>>, <<fsetpos>>, or
<<rewind>>.

The underlying file is not changed, but it is possible to push back
something different than what was originally read.  Ungetting a
character will clear the end-of-stream marker, and decrement the file
position indicator.  Pushing back beyond the beginning of a file gives
unspecified behavior.

The alternate function <<_ungetc_r>> is a reentrant version.  The
extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
The character pushed back, or <<EOF>> on error.

PORTABILITY
ANSI C requires <<ungetc>>, but only requires a pushback buffer of one
byte; although this implementation can handle multiple bytes, not all
can.  Pushing back a signed char is a common application bug.

Supporting OS subroutines required: <<sbrk>>.
*/

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "local.h"

/*
 * Expand the ungetc buffer `in place'.  That is, adjust fp->_p when
 * the buffer moves, so that it points the same distance from the end,
 * and move the bytes in the buffer around as necessary so that they
 * are all at the end (stack-style).
 */

/*static*/
int
_DEFUN(__submore, (rptr, fp),
       struct _reent *rptr _AND
       register FILE *fp)
{
  register int i;
  register unsigned char *p;

  if (fp->_ub._base == fp->_ubuf)
    {
      /*
       * Get a new buffer (rather than expanding the old one).
       */
      if ((p = (unsigned char *) _malloc_r (rptr, (size_t) BUFSIZ)) == NULL)
	return EOF;
      fp->_ub._base = p;
      fp->_ub._size = BUFSIZ;
      p += BUFSIZ - sizeof (fp->_ubuf);
      for (i = sizeof (fp->_ubuf); --i >= 0;)
	p[i] = fp->_ubuf[i];
      fp->_p = p;
      return 0;
    }
  i = fp->_ub._size;
  p = (unsigned char *) _realloc_r (rptr, (_PTR) (fp->_ub._base), i << 1);
  if (p == NULL)
    return EOF;
  _CAST_VOID memcpy ((_PTR) (p + i), (_PTR) p, (size_t) i);
  fp->_p = p + i;
  fp->_ub._base = p;
  fp->_ub._size = i << 1;
  return 0;
}

int
_DEFUN(_ungetc_r, (rptr, c, fp),
       struct _reent *rptr _AND
       int c               _AND
       register FILE *fp)
{
  if (c == EOF)
    return (EOF);

  /* Ensure stdio has been initialized.
     ??? Might be able to remove this as some other stdio routine should
     have already been called to get the char we are un-getting.  */

  CHECK_INIT (rptr, fp);

  _flockfile (fp);

  /* After ungetc, we won't be at eof anymore */
  fp->_flags &= ~__SEOF;

  if ((fp->_flags & __SRD) == 0)
    {
      /*
       * Not already reading: no good unless reading-and-writing.
       * Otherwise, flush any current write stuff.
       */
      if ((fp->_flags & __SRW) == 0)
        {
          _funlockfile (fp);
          return EOF;
        }
      if (fp->_flags & __SWR)
	{
	  if (_fflush_r (rptr, fp))
            {
              _funlockfile (fp);
              return EOF;
            }
	  fp->_flags &= ~__SWR;
	  fp->_w = 0;
	  fp->_lbfsize = 0;
	}
      fp->_flags |= __SRD;
    }
  c = (unsigned char) c;

  /*
   * If we are in the middle of ungetc'ing, just continue.
   * This may require expanding the current ungetc buffer.
   */

  if (HASUB (fp))
    {
      if (fp->_r >= fp->_ub._size && __submore (rptr, fp))
        {
          _funlockfile (fp);
          return EOF;
        }
      *--fp->_p = c;
      fp->_r++;
      _funlockfile (fp);
      return c;
    }

  /*
   * If we can handle this by simply backing up, do so,
   * but never replace the original character.
   * (This makes sscanf() work when scanning `const' data.)
   */

  if (fp->_bf._base != NULL && fp->_p > fp->_bf._base && fp->_p[-1] == c)
    {
      fp->_p--;
      fp->_r++;
      _funlockfile (fp);
      return c;
    }

  /*
   * Create an ungetc buffer.
   * Initially, we will use the `reserve' buffer.
   */

  fp->_ur = fp->_r;
  fp->_up = fp->_p;
  fp->_ub._base = fp->_ubuf;
  fp->_ub._size = sizeof (fp->_ubuf);
  fp->_ubuf[sizeof (fp->_ubuf) - 1] = c;
  fp->_p = &fp->_ubuf[sizeof (fp->_ubuf) - 1];
  fp->_r = 1;
  _funlockfile (fp);
  return c;
}

#ifndef _REENT_ONLY
int
_DEFUN(ungetc, (c, fp),
       int c               _AND
       register FILE *fp)
{
  return _ungetc_r (_REENT, c, fp);
}
#endif /* !_REENT_ONLY */

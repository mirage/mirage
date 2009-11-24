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
/* No user fns here.  Pesch 15apr92. */

#if defined(LIBC_SCCS) && !defined(lint)
static char sccsid[] = "%W% (Berkeley) %G%";
#endif /* LIBC_SCCS and not lint */

#include <_ansi.h>
#include <stdio.h>
#include <errno.h>
#include "local.h"
#include "fvwrite.h"

/*
 * Write the given character into the (probably full) buffer for
 * the given file.  Flush the buffer out if it is or becomes full,
 * or if c=='\n' and the file is line buffered.
 */

int
_DEFUN(__swbuf_r, (ptr, c, fp),
       struct _reent *ptr _AND
       register int c _AND
       register FILE *fp)
{
  register int n;

  /* Ensure stdio has been initialized.  */

  CHECK_INIT (ptr, fp);

  /*
   * In case we cannot write, or longjmp takes us out early,
   * make sure _w is 0 (if fully- or un-buffered) or -_bf._size
   * (if line buffered) so that we will get called again.
   * If we did not do this, a sufficient number of putc()
   * calls might wrap _w from negative to positive.
   */

  fp->_w = fp->_lbfsize;
  if (cantwrite (ptr, fp))
    {
      fp->_flags |= __SERR;
      ptr->_errno = EBADF;
      return EOF;
    }
  c = (unsigned char) c;

  /*
   * If it is completely full, flush it out.  Then, in any case,
   * stuff c into the buffer.  If this causes the buffer to fill
   * completely, or if c is '\n' and the file is line buffered,
   * flush it (perhaps a second time).  The second flush will always
   * happen on unbuffered streams, where _bf._size==1; fflush()
   * guarantees that putc() will always call wbuf() by setting _w
   * to 0, so we need not do anything else.
   */

  n = fp->_p - fp->_bf._base;
  if (n >= fp->_bf._size)
    {
      if (_fflush_r (ptr, fp))
	return EOF;
      n = 0;
    }
  fp->_w--;
  *fp->_p++ = c;
  if (++n == fp->_bf._size || (fp->_flags & __SLBF && c == '\n'))
    if (_fflush_r (ptr, fp))
      return EOF;
  return c;
}

/* This function isn't any longer declared in stdio.h, but it's
   required for backward compatibility with applications built against
   earlier dynamically built newlib libraries. */
int
_DEFUN(__swbuf, (c, fp),
       register int c _AND
       register FILE *fp)
{
  return __swbuf_r (_REENT, c, fp);
}

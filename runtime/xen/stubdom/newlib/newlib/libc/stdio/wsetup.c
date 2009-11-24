/* No user fns here. Pesch 15apr92. */

/*
 * Copyright (c) 1990, 2007 The Regents of the University of California.
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

#include <_ansi.h>
#include <stdio.h>
#include <stdlib.h>
#include "local.h"

/*
 * Various output routines call wsetup to be sure it is safe to write,
 * because either _flags does not include __SWR, or _buf is NULL.
 * _wsetup returns 0 if OK to write, nonzero otherwise.
 */

int
_DEFUN(__swsetup_r, (ptr, fp),
       struct _reent *ptr _AND
       register FILE * fp)
{
  /* Make sure stdio is set up.  */

  CHECK_INIT (_REENT, fp);

  /*
   * If we are not writing, we had better be reading and writing.
   */

  if ((fp->_flags & __SWR) == 0)
    {
      if ((fp->_flags & __SRW) == 0)
	return EOF;
      if (fp->_flags & __SRD)
	{
	  /* clobber any ungetc data */
	  if (HASUB (fp))
	    FREEUB (ptr, fp);
	  fp->_flags &= ~(__SRD | __SEOF);
	  fp->_r = 0;
	  fp->_p = fp->_bf._base;
	}
      fp->_flags |= __SWR;
    }

  /*
   * Make a buffer if necessary, then set _w.
   * A string I/O file should not explicitly allocate a buffer
   * unless asprintf is being used.
   */
  if (fp->_bf._base == NULL 
        && (!(fp->_flags & __SSTR) || (fp->_flags & __SMBF)))
    __smakebuf_r (ptr, fp);

  if (fp->_flags & __SLBF)
    {
      /*
       * It is line buffered, so make _lbfsize be -_bufsize
       * for the putc() macro.  We will change _lbfsize back
       * to 0 whenever we turn off __SWR.
       */
      fp->_w = 0;
      fp->_lbfsize = -fp->_bf._size;
    }
  else
    fp->_w = fp->_flags & __SNBF ? 0 : fp->_bf._size;

  return (!fp->_bf._base && (fp->_flags & __SMBF)) ? EOF : 0;
}

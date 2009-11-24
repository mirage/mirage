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
<<fclose>>---close a file

INDEX
	fclose
INDEX
	_fclose_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int fclose(FILE *<[fp]>);
	int _fclose_r(struct _reent *<[reent]>, FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int fclose(<[fp]>)
	FILE *<[fp]>;

	int fclose(<[fp]>)
        struct _reent *<[reent]>
	FILE *<[fp]>;

DESCRIPTION
If the file or stream identified by <[fp]> is open, <<fclose>> closes
it, after first ensuring that any pending data is written (by calling
<<fflush(<[fp]>)>>).

The alternate function <<_fclose_r>> is a reentrant version.
The extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
<<fclose>> returns <<0>> if successful (including when <[fp]> is
<<NULL>> or not an open file); otherwise, it returns <<EOF>>.

PORTABILITY
<<fclose>> is required by ANSI C.

Required OS subroutines: <<close>>, <<fstat>>, <<isatty>>, <<lseek>>,
<<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/lock.h>
#include "local.h"

int
_DEFUN(_fclose_r, (rptr, fp),
      struct _reent *rptr _AND
      register FILE * fp)
{
  int r;

  if (fp == NULL)
    return (0);			/* on NULL */

  __sfp_lock_acquire ();

  CHECK_INIT (rptr, fp);

  _flockfile (fp);

  if (fp->_flags == 0)		/* not open! */
    {
      _funlockfile (fp);
      __sfp_lock_release ();
      return (0);
    }
  /* Unconditionally flush to allow special handling for seekable read
     files to reposition file to last byte processed as opposed to
     last byte read ahead into the buffer.  */
  r = _fflush_r (rptr, fp);
  if (fp->_close != NULL && fp->_close (rptr, fp->_cookie) < 0)
    r = EOF;
  if (fp->_flags & __SMBF)
    _free_r (rptr, (char *) fp->_bf._base);
  if (HASUB (fp))
    FREEUB (rptr, fp);
  if (HASLB (fp))
    FREELB (rptr, fp);
  fp->_flags = 0;		/* release this FILE for reuse */
  _funlockfile (fp);
#ifndef __SINGLE_THREAD__
  __lock_close_recursive (fp->_lock);
#endif

  __sfp_lock_release ();

  return (r);
}

#ifndef _REENT_ONLY

int
_DEFUN(fclose, (fp),
       register FILE * fp)
{
  return _fclose_r(_REENT, fp);
}

#endif

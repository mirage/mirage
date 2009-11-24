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
<<fflush>>---flush buffered file output

INDEX
	fflush

ANSI_SYNOPSIS
	#include <stdio.h>
	int fflush(FILE *<[fp]>);

	int _fflush_r(struct _reent *<[reent]>, FILE *<[fp]>);

DESCRIPTION
The <<stdio>> output functions can buffer output before delivering it
to the host system, in order to minimize the overhead of system calls.

Use <<fflush>> to deliver any such pending output (for the file
or stream identified by <[fp]>) to the host system.

If <[fp]> is <<NULL>>, <<fflush>> delivers pending output from all
open files.

Additionally, if <[fp]> is a seekable input stream visiting a file
descriptor, set the position of the file descriptor to match next
unread byte, useful for obeying POSIX semantics when ending a process
without consuming all input from the stream.

The alternate function <<_fflush_r>> is a reentrant version, where the
extra argument <[reent]> is a pointer to a reentrancy structure, and
<[fp]> must not be NULL.

RETURNS
<<fflush>> returns <<0>> unless it encounters a write error; in that
situation, it returns <<EOF>>.

PORTABILITY
ANSI C requires <<fflush>>.  The behavior on input streams is only
specified by POSIX, and not all implementations follow POSIX rules.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <stdio.h>
#include <errno.h>
#include "local.h"

/* Flush a single file, or (if fp is NULL) all files.  */

int
_DEFUN(_fflush_r, (ptr, fp),
       struct _reent *ptr _AND
       register FILE * fp)
{
  register unsigned char *p;
  register int n, t;

#ifdef _REENT_SMALL
  /* For REENT_SMALL platforms, it is possible we are being
     called for the first time on a std stream.  This std
     stream can belong to a reentrant struct that is not
     _REENT.  If CHECK_INIT gets called below based on _REENT,
     we will end up changing said file pointers to the equivalent
     std stream off of _REENT.  This causes unexpected behavior if
     there is any data to flush on the _REENT std stream.  There
     are two alternatives to fix this:  1) make a reentrant fflush
     or 2) simply recognize that this file has nothing to flush
     and return immediately before performing a CHECK_INIT.  Choice
     2 is implemented here due to its simplicity.  */
  if (fp->_bf._base == NULL)
    return 0;
#endif /* _REENT_SMALL  */

  CHECK_INIT (ptr, fp);

  _flockfile (fp);

  t = fp->_flags;
  if ((t & __SWR) == 0)
    {
      /* For a read stream, an fflush causes the next seek to be
         unoptimized (i.e. forces a system-level seek).  This conforms
         to the POSIX and SUSv3 standards.  */
      fp->_flags |= __SNPT;

      /* For a seekable stream with buffered read characters, we will attempt
         a seek to the current position now.  A subsequent read will then get
         the next byte from the file rather than the buffer.  This conforms
         to the POSIX and SUSv3 standards.  Note that the standards allow
         this seek to be deferred until necessary, but we choose to do it here
         to make the change simpler, more contained, and less likely
         to miss a code scenario.  */
      if ((fp->_r > 0 || fp->_ur > 0) && fp->_seek != NULL)
	{
	  int tmp;
#ifdef __LARGE64_FILES
	  _fpos64_t curoff;
#else
	  _fpos_t curoff;
#endif

	  /* Get the physical position we are at in the file.  */
	  if (fp->_flags & __SOFF)
	    curoff = fp->_offset;
	  else
	    {
	      /* We don't know current physical offset, so ask for it.
		 Only ESPIPE is ignorable.  */
#ifdef __LARGE64_FILES
	      if (fp->_flags & __SL64)
		curoff = fp->_seek64 (ptr, fp->_cookie, 0, SEEK_CUR);
	      else
#endif
		curoff = fp->_seek (ptr, fp->_cookie, 0, SEEK_CUR);
	      if (curoff == -1L)
		{
		  int result = EOF;
		  if (ptr->_errno == ESPIPE)
		    result = 0;
		  else
		    fp->_flags |= __SERR;
		  _funlockfile (fp);
		  return result;
		}
            }
          if (fp->_flags & __SRD)
            {
              /* Current offset is at end of buffer.  Compensate for
                 characters not yet read.  */
              curoff -= fp->_r;
              if (HASUB (fp))
                curoff -= fp->_ur;
            }
	  /* Now physically seek to after byte last read.  */
#ifdef __LARGE64_FILES
	  if (fp->_flags & __SL64)
	    tmp = (fp->_seek64 (ptr, fp->_cookie, curoff, SEEK_SET) == curoff);
	  else
#endif
	    tmp = (fp->_seek (ptr, fp->_cookie, curoff, SEEK_SET) == curoff);
	  if (tmp)
	    {
	      /* Seek successful.  We can clear read buffer now.  */
	      fp->_flags &= ~__SNPT;
	      fp->_r = 0;
	      fp->_p = fp->_bf._base;
	      if (fp->_flags & __SOFF)
		fp->_offset = curoff;
	    }
	  else
	    {
	      fp->_flags |= __SERR;
	      _funlockfile (fp);
	      return EOF;
	    }
	}
      _funlockfile (fp);
      return 0;
    }
  if ((p = fp->_bf._base) == NULL)
    {
      /* Nothing to flush.  */
      _funlockfile (fp);
      return 0;
    }
  n = fp->_p - p;		/* write this much */

  /*
   * Set these immediately to avoid problems with longjmp
   * and to allow exchange buffering (via setvbuf) in user
   * write function.
   */
  fp->_p = p;
  fp->_w = t & (__SLBF | __SNBF) ? 0 : fp->_bf._size;

  while (n > 0)
    {
      t = fp->_write (ptr, fp->_cookie, (char *) p, n);
      if (t <= 0)
	{
          fp->_flags |= __SERR;
          _funlockfile (fp);
          return EOF;
	}
      p += t;
      n -= t;
    }
  _funlockfile (fp);
  return 0;
}

#ifndef _REENT_ONLY

int
_DEFUN(fflush, (fp),
       register FILE * fp)
{
  if (fp == NULL)
    return _fwalk_reent (_GLOBAL_REENT, _fflush_r);

  return _fflush_r (_REENT, fp);
}

#endif /* _REENT_ONLY */

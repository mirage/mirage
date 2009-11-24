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
/* No user fns here.  Pesch 15apr92. */

#include <_ansi.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/unistd.h>
#include "local.h"

#define _DEFAULT_ASPRINTF_BUFSIZE 64

/*
 * Allocate a file buffer, or switch to unbuffered I/O.
 * Per the ANSI C standard, ALL tty devices default to line buffered.
 *
 * As a side effect, we set __SOPT or __SNPT (en/dis-able fseek
 * optimization) right after the _fstat() that finds the buffer size.
 */

_VOID
_DEFUN(__smakebuf_r, (ptr, fp),
       struct _reent *ptr _AND
       register FILE *fp)
{
  register size_t size, couldbetty;
  register _PTR p;
#ifdef __USE_INTERNAL_STAT64
  struct stat64 st;
#else
  struct stat st;
#endif

  if (fp->_flags & __SNBF)
    {
      fp->_bf._base = fp->_p = fp->_nbuf;
      fp->_bf._size = 1;
      return;
    }
#ifdef __USE_INTERNAL_STAT64
  if (fp->_file < 0 || _fstat64_r (ptr, fp->_file, &st) < 0)
#else
  if (fp->_file < 0 || _fstat_r (ptr, fp->_file, &st) < 0)
#endif
    {
      couldbetty = 0;
      /* Check if we are be called by asprintf family for initial buffer.  */
      if (fp->_flags & __SMBF)
        size = _DEFAULT_ASPRINTF_BUFSIZE;
      else
        size = BUFSIZ;
      /* do not try to optimise fseek() */
      fp->_flags |= __SNPT;
    }
  else
    {
      couldbetty = (st.st_mode & S_IFMT) == S_IFCHR;
#ifdef HAVE_BLKSIZE
      size = st.st_blksize <= 0 ? BUFSIZ : st.st_blksize;
#else
      size = BUFSIZ;
#endif
      /*
       * Optimize fseek() only if it is a regular file.
       * (The test for __sseek is mainly paranoia.)
       */
      if ((st.st_mode & S_IFMT) == S_IFREG && fp->_seek == __sseek)
	{
	  fp->_flags |= __SOPT;
#ifdef HAVE_BLKSIZE
	  fp->_blksize = st.st_blksize;
#else
	  fp->_blksize = 1024;
#endif
	}
      else
	fp->_flags |= __SNPT;
    }
  if ((p = _malloc_r (ptr, size)) == NULL)
    {
      if (!(fp->_flags & __SSTR))
	{
	  fp->_flags |= __SNBF;
	  fp->_bf._base = fp->_p = fp->_nbuf;
	  fp->_bf._size = 1;
	}
    }
  else
    {
      ptr->__cleanup = _cleanup_r;
      fp->_flags |= __SMBF;
      fp->_bf._base = fp->_p = (unsigned char *) p;
      fp->_bf._size = size;
      if (couldbetty && isatty (fp->_file))
	fp->_flags |= __SLBF;
    }
}

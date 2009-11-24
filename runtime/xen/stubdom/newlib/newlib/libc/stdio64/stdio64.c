/* No user fns here.  Pesch 15apr92. */

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

#include <stdio.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/unistd.h>
#include <errno.h>
#include "local.h"

#ifdef __LARGE64_FILES
_fpos64_t
_DEFUN(__sseek64, (ptr, cookie, offset, whence),
       struct _reent *ptr _AND
       void *cookie _AND
       _fpos64_t offset _AND
       int whence)
{
  register FILE *fp = (FILE *) cookie;
  register _off64_t ret;

  ret = _lseek64_r (ptr, fp->_file, (_off64_t) offset, whence);
  if (ret == (_fpos64_t)-1L)
    fp->_flags &= ~__SOFF;
  else
    {
      fp->_flags |= __SOFF;
      fp->_offset = ret;
    }
  return ret;
}

_READ_WRITE_RETURN_TYPE
_DEFUN(__swrite64, (ptr, cookie, buf, n),
       struct _reent *ptr _AND
       void *cookie _AND
       char const *buf _AND
       int n)
{
  register FILE *fp = (FILE *) cookie;
  int w;
#ifdef __SCLE
  int oldmode=0;
#endif

  if (fp->_flags & __SAPP)
    (void) _lseek64_r (ptr, fp->_file, (_off64_t)0, SEEK_END);
  fp->_flags &= ~__SOFF;	/* in case O_APPEND mode is set */

#ifdef __SCLE
  if (fp->_flags & __SCLE)
    oldmode = setmode(fp->_file, O_BINARY);
#endif

  w = _write_r (ptr, fp->_file, buf, n);

#ifdef __SCLE
  if (oldmode)
    setmode(fp->_file, oldmode);
#endif

  return w;
}

#endif /* __LARGE64_FILES */

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
<<fdopen>>---turn open file into a stream

INDEX
	fdopen
INDEX
	_fdopen_r

ANSI_SYNOPSIS
	#include <stdio.h>
	FILE *fdopen(int <[fd]>, const char *<[mode]>);
	FILE *_fdopen_r(struct _reent *<[reent]>,
                        int <[fd]>, const char *<[mode]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	FILE *fdopen(<[fd]>, <[mode]>)
	int <[fd]>;
	char *<[mode]>;

	FILE *_fdopen_r(<[reent]>, <[fd]>, <[mode]>)
	struct _reent *<[reent]>;
        int <[fd]>;
	char *<[mode]>);

DESCRIPTION
<<fdopen>> produces a file descriptor of type <<FILE *>>, from a
descriptor for an already-open file (returned, for example, by the
system subroutine <<open>> rather than by <<fopen>>).
The <[mode]> argument has the same meanings as in <<fopen>>.

RETURNS
File pointer or <<NULL>>, as for <<fopen>>.

PORTABILITY
<<fdopen>> is ANSI.
*/

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include <sys/fcntl.h>
#include <stdio.h>
#include <errno.h>
#include "local.h"
#include <_syslist.h>

FILE *
_DEFUN(_fdopen_r, (ptr, fd, mode),
       struct _reent *ptr _AND
       int fd             _AND
       _CONST char *mode)
{
  register FILE *fp;
  int flags, oflags;
#ifdef HAVE_FCNTL
  int fdflags, fdmode;
#endif

  if ((flags = __sflags (ptr, mode, &oflags)) == 0)
    return 0;

  /* make sure the mode the user wants is a subset of the actual mode */
#ifdef HAVE_FCNTL
  if ((fdflags = _fcntl_r (ptr, fd, F_GETFL, 0)) < 0)
    return 0;
  fdmode = fdflags & O_ACCMODE;
  if (fdmode != O_RDWR && (fdmode != (oflags & O_ACCMODE)))
    {
      ptr->_errno = EBADF;
      return 0;
    }
#endif

  if ((fp = __sfp (ptr)) == 0)
    return 0;

  _flockfile (fp);

  fp->_flags = flags;
  /* POSIX recommends setting the O_APPEND bit on fd to match append
     streams.  Someone may later clear O_APPEND on fileno(fp), but the
     stream must still remain in append mode.  Rely on __sflags
     setting __SAPP properly.  */
#ifdef HAVE_FCNTL
  if ((oflags & O_APPEND) && !(fdflags & O_APPEND))
    _fcntl_r (ptr, fd, F_SETFL, fdflags | O_APPEND);
#endif
  fp->_file = fd;
  fp->_cookie = (_PTR) fp;

#undef _read
#undef _write
#undef _seek
#undef _close

  fp->_read = __sread;
  fp->_write = __swrite;
  fp->_seek = __sseek;
  fp->_close = __sclose;

#ifdef __SCLE
  /* Explicit given mode results in explicit setting mode on fd */
  if (oflags & O_BINARY)
    setmode (fp->_file, O_BINARY);
  else if (oflags & O_TEXT)
    setmode (fp->_file, O_TEXT);
  if (__stextmode (fp->_file))
    fp->_flags |= __SCLE;
#endif

  _funlockfile (fp);
  return fp;
}

#ifndef _REENT_ONLY

FILE *
_DEFUN(fdopen, (fd, mode),
       int fd _AND
       _CONST char *mode)
{
  return _fdopen_r (_REENT, fd, mode);
}

#endif

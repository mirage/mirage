/*
FUNCTION
<<fdopen64>>---turn open file into a stream

INDEX
	fdopen64
INDEX
	_fdopen64_r

SYNOPSIS
	#include <stdio.h>
	FILE *fdopen64(int <[fd]>, const char *<[mode]>);
	FILE *_fdopen64_r(void *<[reent]>,
                     int <[fd]>, const char *<[mode]>);

DESCRIPTION
<<fdopen64>> produces a file descriptor of type <<FILE *>>, from a
descriptor for an already-open file (returned, for example, by the
system subroutine <<open>> rather than by <<fopen>>).
The <[mode]> argument has the same meanings as in <<fopen>>.

RETURNS
File pointer or <<NULL>>, as for <<fopen>>.
*/

#include <sys/types.h>
#include <sys/fcntl.h>

#include <stdio.h>
#include <errno.h>
#include "local.h"
#include <_syslist.h>
#include <sys/lock.h>

extern int __sflags ();

FILE *
_DEFUN (_fdopen64_r, (ptr, fd, mode),
	struct _reent *ptr _AND
	int fd _AND
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

  _flockfile(fp);

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
  fp->_write = __swrite64;
  fp->_seek = __sseek;
  fp->_seek64 = __sseek64;
  fp->_close = __sclose;

#ifdef __SCLE
  /* Explicit given mode results in explicit setting mode on fd */
  if (oflags & O_BINARY)
    setmode(fp->_file, O_BINARY);
  else if (oflags & O_TEXT)
    setmode(fp->_file, O_TEXT);
  if (__stextmode(fp->_file))
    fp->_flags |= __SCLE;
#endif

  fp->_flags |= __SL64;

  _funlockfile(fp);
  return fp;
}

#ifndef _REENT_ONLY

FILE *
_DEFUN (fdopen64, (fd, mode),
	int fd _AND
	_CONST char *mode)
{
  return _fdopen64_r (_REENT, fd, mode);
}

#endif

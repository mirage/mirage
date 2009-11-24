/* Copyright (C) 2007 Eric Blake
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

/*
FUNCTION
<<fopencookie>>---open a stream with custom callbacks

INDEX
	fopencookie

ANSI_SYNOPSIS
	#include <stdio.h>
	typedef ssize_t (*cookie_read_function_t)(void *_cookie, char *_buf,
						  size_t _n);
	typedef ssize_t (*cookie_write_function_t)(void *_cookie,
						   const char *_buf, size_t _n);
	typedef int (*cookie_seek_function_t)(void *_cookie, off_t *_off,
					      int _whence);
	typedef int (*cookie_close_function_t)(void *_cookie);
	FILE *fopencookie(const void *<[cookie]>, const char *<[mode]>,
			  cookie_io_functions_t <[functions]>);

DESCRIPTION
<<fopencookie>> creates a <<FILE>> stream where I/O is performed using
custom callbacks.  The callbacks are registered via the structure:

.	typedef struct
.	{
.		cookie_read_function_t	*read;
.		cookie_write_function_t *write;
.		cookie_seek_function_t	*seek;
.		cookie_close_function_t *close;
.	} cookie_io_functions_t;

The stream is opened with <[mode]> treated as in <<fopen>>.  The
callbacks <[functions.read]> and <[functions.write]> may only be NULL
when <[mode]> does not require them.

<[functions.read]> should return -1 on failure, or else the number of
bytes read (0 on EOF).  It is similar to <<read>>, except that
<[cookie]> will be passed as the first argument.

<[functions.write]> should return -1 on failure, or else the number of
bytes written.  It is similar to <<write>>, except that <[cookie]>
will be passed as the first argument.

<[functions.seek]> should return -1 on failure, and 0 on success, with
*<[_off]> set to the current file position.  It is a cross between
<<lseek>> and <<fseek>>, with the <[_whence]> argument interpreted in
the same manner.  A NULL <[functions.seek]> makes the stream behave
similarly to a pipe in relation to stdio functions that require
positioning.

<[functions.close]> should return -1 on failure, or 0 on success.  It
is similar to <<close>>, except that <[cookie]> will be passed as the
first argument.  A NULL <[functions.close]> merely flushes all data
then lets <<fclose>> succeed.  A failed close will still invalidate
the stream.

Read and write I/O functions are allowed to change the underlying
buffer on fully buffered or line buffered streams by calling
<<setvbuf>>.  They are also not required to completely fill or empty
the buffer.  They are not, however, allowed to change streams from
unbuffered to buffered or to change the state of the line buffering
flag.  They must also be prepared to have read or write calls occur on
buffers other than the one most recently specified.

RETURNS
The return value is an open FILE pointer on success.  On error,
<<NULL>> is returned, and <<errno>> will be set to EINVAL if a
function pointer is missing or <[mode]> is invalid, ENOMEM if the
stream cannot be created, or EMFILE if too many streams are already
open.

PORTABILITY
This function is a newlib extension, copying the prototype from Linux.
It is not portable.  See also the <<funopen>> interface from BSD.

Supporting OS subroutines required: <<sbrk>>.
*/

#include <stdio.h>
#include <errno.h>
#include <sys/lock.h>
#include "local.h"

typedef struct fccookie {
  void *cookie;
  FILE *fp;
  cookie_read_function_t *readfn;
  cookie_write_function_t *writefn;
  cookie_seek_function_t *seekfn;
  cookie_close_function_t *closefn;
} fccookie;

static _READ_WRITE_RETURN_TYPE
_DEFUN(fcreader, (ptr, cookie, buf, n),
       struct _reent *ptr _AND
       void *cookie _AND
       char *buf _AND
       int n)
{
  int result;
  fccookie *c = (fccookie *) cookie;
  errno = 0;
  if ((result = c->readfn (c->cookie, buf, n)) < 0 && errno)
    ptr->_errno = errno;
  return result;
}

static _READ_WRITE_RETURN_TYPE
_DEFUN(fcwriter, (ptr, cookie, buf, n),
       struct _reent *ptr _AND
       void *cookie _AND
       const char *buf _AND
       int n)
{
  int result;
  fccookie *c = (fccookie *) cookie;
  if (c->fp->_flags & __SAPP && c->fp->_seek)
    {
#ifdef __LARGE64_FILES
      c->fp->_seek64 (ptr, cookie, 0, SEEK_END);
#else
      c->fp->_seek (ptr, cookie, 0, SEEK_END);
#endif
    }
  errno = 0;
  if ((result = c->writefn (c->cookie, buf, n)) < 0 && errno)
    ptr->_errno = errno;
  return result;
}

static _fpos_t
_DEFUN(fcseeker, (ptr, cookie, pos, whence),
       struct _reent *ptr _AND
       void *cookie _AND
       _fpos_t pos _AND
       int whence)
{
  fccookie *c = (fccookie *) cookie;
#ifndef __LARGE64_FILES
  off_t offset = (off_t) pos;
#else /* __LARGE64_FILES */
  _off64_t offset = (_off64_t) pos;
#endif /* __LARGE64_FILES */

  errno = 0;
  if (c->seekfn (c->cookie, &offset, whence) < 0 && errno)
    ptr->_errno = errno;
#ifdef __LARGE64_FILES
  else if ((_fpos_t)offset != offset)
    {
      ptr->_errno = EOVERFLOW;
      offset = -1;
    }
#endif /* __LARGE64_FILES */
  return (_fpos_t) offset;
}

#ifdef __LARGE64_FILES
static _fpos64_t
_DEFUN(fcseeker64, (ptr, cookie, pos, whence),
       struct _reent *ptr _AND
       void *cookie _AND
       _fpos64_t pos _AND
       int whence)
{
  _off64_t offset;
  fccookie *c = (fccookie *) cookie;
  errno = 0;
  if (c->seekfn (c->cookie, &offset, whence) < 0 && errno)
    ptr->_errno = errno;
  return (_fpos64_t) offset;
}
#endif /* __LARGE64_FILES */

static int
_DEFUN(fccloser, (ptr, cookie),
       struct _reent *ptr _AND
       void *cookie)
{
  int result = 0;
  fccookie *c = (fccookie *) cookie;
  if (c->closefn)
    {
      errno = 0;
      if ((result = c->closefn (c->cookie)) < 0 && errno)
	ptr->_errno = errno;
    }
  _free_r (ptr, c);
  return result;
}

FILE *
_DEFUN(_fopencookie_r, (ptr, cookie, mode, functions),
       struct _reent *ptr _AND
       void *cookie _AND
       const char *mode _AND
       cookie_io_functions_t functions)
{
  FILE *fp;
  fccookie *c;
  int flags;
  int dummy;

  if ((flags = __sflags (ptr, mode, &dummy)) == 0)
    return NULL;
  if (((flags & (__SRD | __SRW)) && !functions.read)
      || ((flags & (__SWR | __SRW)) && !functions.write))
    {
      ptr->_errno = EINVAL;
      return NULL;
    }
  if ((fp = __sfp (ptr)) == NULL)
    return NULL;
  if ((c = (fccookie *) _malloc_r (ptr, sizeof *c)) == NULL)
    {
      __sfp_lock_acquire ();
      fp->_flags = 0;		/* release */
#ifndef __SINGLE_THREAD__
      __lock_close_recursive (fp->_lock);
#endif
      __sfp_lock_release ();
      return NULL;
    }

  _flockfile (fp);
  fp->_file = -1;
  fp->_flags = flags;
  c->cookie = cookie;
  c->fp = fp;
  fp->_cookie = c;
  c->readfn = functions.read;
  fp->_read = fcreader;
  c->writefn = functions.write;
  fp->_write = fcwriter;
  c->seekfn = functions.seek;
  fp->_seek = functions.seek ? fcseeker : NULL;
#ifdef __LARGE64_FILES
  fp->_seek64 = functions.seek ? fcseeker64 : NULL;
  fp->_flags |= __SL64;
#endif
  c->closefn = functions.close;
  fp->_close = fccloser;
  _funlockfile (fp);
  return fp;
}

#ifndef _REENT_ONLY
FILE *
_DEFUN(fopencookie, (cookie, mode, functions),
       void *cookie _AND
       const char *mode _AND
       cookie_io_functions_t functions)
{
  return _fopencookie_r (_REENT, cookie, mode, functions);
}
#endif /* !_REENT_ONLY */

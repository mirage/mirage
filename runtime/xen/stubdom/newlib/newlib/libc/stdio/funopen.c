/* Copyright (C) 2007 Eric Blake
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

/*
FUNCTION
<<funopen>>, <<fropen>>, <<fwopen>>---open a stream with custom callbacks

INDEX
	funopen
INDEX
	fropen
INDEX
	fwopen

ANSI_SYNOPSIS
	#include <stdio.h>
	FILE *funopen(const void *<[cookie]>,
	              int (*<[readfn]>) (void *cookie, char *buf, int n),
	              int (*<[writefn]>) (void *cookie, const char *buf, int n),
	              fpos_t (*<[seekfn]>) (void *cookie, fpos_t off, int whence),
	              int (*<[closefn]>) (void *cookie));
	FILE *fropen(const void *<[cookie]>,
	             int (*<[readfn]>) (void *cookie, char *buf, int n));
	FILE *fwopen(const void *<[cookie]>,
	             int (*<[writefn]>) (void *cookie, const char *buf, int n));

DESCRIPTION
<<funopen>> creates a <<FILE>> stream where I/O is performed using
custom callbacks.  At least one of <[readfn]> and <[writefn]> must be
provided, which determines whether the stream behaves with mode <"r">,
<"w">, or <"r+">.

<[readfn]> should return -1 on failure, or else the number of bytes
read (0 on EOF).  It is similar to <<read>>, except that <int> rather
than <size_t> bounds a transaction size, and <[cookie]> will be passed
as the first argument.  A NULL <[readfn]> makes attempts to read the
stream fail.

<[writefn]> should return -1 on failure, or else the number of bytes
written.  It is similar to <<write>>, except that <int> rather than
<size_t> bounds a transaction size, and <[cookie]> will be passed as
the first argument.  A NULL <[writefn]> makes attempts to write the
stream fail.

<[seekfn]> should return (fpos_t)-1 on failure, or else the current
file position.  It is similar to <<lseek>>, except that <[cookie]>
will be passed as the first argument.  A NULL <[seekfn]> makes the
stream behave similarly to a pipe in relation to stdio functions that
require positioning.  This implementation assumes fpos_t and off_t are
the same type.

<[closefn]> should return -1 on failure, or 0 on success.  It is
similar to <<close>>, except that <[cookie]> will be passed as the
first argument.  A NULL <[closefn]> merely flushes all data then lets
<<fclose>> succeed.  A failed close will still invalidate the stream.

Read and write I/O functions are allowed to change the underlying
buffer on fully buffered or line buffered streams by calling
<<setvbuf>>.  They are also not required to completely fill or empty
the buffer.  They are not, however, allowed to change streams from
unbuffered to buffered or to change the state of the line buffering
flag.  They must also be prepared to have read or write calls occur on
buffers other than the one most recently specified.

The functions <<fropen>> and <<fwopen>> are convenience macros around
<<funopen>> that only use the specified callback.

RETURNS
The return value is an open FILE pointer on success.  On error,
<<NULL>> is returned, and <<errno>> will be set to EINVAL if a
function pointer is missing, ENOMEM if the stream cannot be created,
or EMFILE if too many streams are already open.

PORTABILITY
This function is a newlib extension, copying the prototype from BSD.
It is not portable.  See also the <<fopencookie>> interface from Linux.

Supporting OS subroutines required: <<sbrk>>.
*/

#include <stdio.h>
#include <errno.h>
#include <sys/lock.h>
#include "local.h"

typedef int (*funread)(void *_cookie, char *_buf, int _n);
typedef int (*funwrite)(void *_cookie, const char *_buf, int _n);
#ifdef __LARGE64_FILES
typedef _fpos64_t (*funseek)(void *_cookie, _fpos64_t _off, int _whence);
#else
typedef fpos_t (*funseek)(void *_cookie, fpos_t _off, int _whence);
#endif
typedef int (*funclose)(void *_cookie);

typedef struct funcookie {
  void *cookie;
  funread readfn;
  funwrite writefn;
  funseek seekfn;
  funclose closefn;
} funcookie;

static _READ_WRITE_RETURN_TYPE
_DEFUN(funreader, (ptr, cookie, buf, n),
       struct _reent *ptr _AND
       void *cookie _AND
       char *buf _AND
       int n)
{
  int result;
  funcookie *c = (funcookie *) cookie;
  errno = 0;
  if ((result = c->readfn (c->cookie, buf, n)) < 0 && errno)
    ptr->_errno = errno;
  return result;
}

static _READ_WRITE_RETURN_TYPE
_DEFUN(funwriter, (ptr, cookie, buf, n),
       struct _reent *ptr _AND
       void *cookie _AND
       const char *buf _AND
       int n)
{
  int result;
  funcookie *c = (funcookie *) cookie;
  errno = 0;
  if ((result = c->writefn (c->cookie, buf, n)) < 0 && errno)
    ptr->_errno = errno;
  return result;
}

static _fpos_t
_DEFUN(funseeker, (ptr, cookie, off, whence),
       struct _reent *ptr _AND
       void *cookie _AND
       _fpos_t off _AND
       int whence)
{
  funcookie *c = (funcookie *) cookie;
#ifndef __LARGE64_FILES
  fpos_t result;
  errno = 0;
  if ((result = c->seekfn (c->cookie, (fpos_t) off, whence)) < 0 && errno)
    ptr->_errno = errno;
#else /* __LARGE64_FILES */
  _fpos64_t result;
  errno = 0;
  if ((result = c->seekfn (c->cookie, (_fpos64_t) off, whence)) < 0 && errno)
    ptr->_errno = errno;
  else if ((_fpos_t)result != result)
    {
      ptr->_errno = EOVERFLOW;
      result = -1;
    }
#endif /* __LARGE64_FILES */
  return result;
}

#ifdef __LARGE64_FILES
static _fpos64_t
_DEFUN(funseeker64, (ptr, cookie, off, whence),
       struct _reent *ptr _AND
       void *cookie _AND
       _fpos64_t off _AND
       int whence)
{
  _fpos64_t result;
  funcookie *c = (funcookie *) cookie;
  errno = 0;
  if ((result = c->seekfn (c->cookie, off, whence)) < 0 && errno)
    ptr->_errno = errno;
  return result;
}
#endif /* __LARGE64_FILES */

static int
_DEFUN(funcloser, (ptr, cookie),
       struct _reent *ptr _AND
       void *cookie)
{
  int result = 0;
  funcookie *c = (funcookie *) cookie;
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
_DEFUN(_funopen_r, (ptr, cookie, readfn, writefn, seekfn, closefn),
       struct _reent *ptr _AND
       const void *cookie _AND
       funread readfn _AND
       funwrite writefn _AND
       funseek seekfn _AND
       funclose closefn)
{
  FILE *fp;
  funcookie *c;

  if (!readfn && !writefn)
    {
      ptr->_errno = EINVAL;
      return NULL;
    }
  if ((fp = __sfp (ptr)) == NULL)
    return NULL;
  if ((c = (funcookie *) _malloc_r (ptr, sizeof *c)) == NULL)
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
  c->cookie = (void *) cookie; /* cast away const */
  fp->_cookie = c;
  if (readfn)
    {
      c->readfn = readfn;
      fp->_read = funreader;
      if (writefn)
	{
	  fp->_flags = __SRW;
	  c->writefn = writefn;
	  fp->_write = funwriter;
	}
      else
	{
	  fp->_flags = __SRD;
	  c->writefn = NULL;
	  fp->_write = NULL;
	}
    }
  else
    {
      fp->_flags = __SWR;
      c->writefn = writefn;
      fp->_write = funwriter;
      c->readfn = NULL;
      fp->_read = NULL;
    }
  c->seekfn = seekfn;
  fp->_seek = seekfn ? funseeker : NULL;
#ifdef __LARGE64_FILES
  fp->_seek64 = seekfn ? funseeker64 : NULL;
  fp->_flags |= __SL64;
#endif
  c->closefn = closefn;
  fp->_close = funcloser;
  _funlockfile (fp);
  return fp;
}

#ifndef _REENT_ONLY
FILE *
_DEFUN(funopen, (cookie, readfn, writefn, seekfn, closefn),
       const void *cookie _AND
       funread readfn _AND
       funwrite writefn _AND
       funseek seekfn _AND
       funclose closefn)
{
  return _funopen_r (_REENT, cookie, readfn, writefn, seekfn, closefn);
}
#endif /* !_REENT_ONLY */

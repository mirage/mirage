/* Copyright (C) 2007 Eric Blake
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

/*
FUNCTION
<<fmemopen>>---open a stream around a fixed-length string

INDEX
	fmemopen

ANSI_SYNOPSIS
	#include <stdio.h>
	FILE *fmemopen(void *restrict <[buf]>, size_t <[size]>,
		       const char *restrict <[mode]>);

DESCRIPTION
<<fmemopen>> creates a seekable <<FILE>> stream that wraps a
fixed-length buffer of <[size]> bytes starting at <[buf]>.  The stream
is opened with <[mode]> treated as in <<fopen>>, where append mode
starts writing at the first NUL byte.  If <[buf]> is NULL, then
<[size]> bytes are automatically provided as if by <<malloc>>, with
the initial size of 0, and <[mode]> must contain <<+>> so that data
can be read after it is written.

The stream maintains a current position, which moves according to
bytes read or written, and which can be one past the end of the array.
The stream also maintains a current file size, which is never greater
than <[size]>.  If <[mode]> starts with <<r>>, the position starts at
<<0>>, and file size starts at <[size]> if <[buf]> was provided.  If
<[mode]> starts with <<w>>, the position and file size start at <<0>>,
and if <[buf]> was provided, the first byte is set to NUL.  If
<[mode]> starts with <<a>>, the position and file size start at the
location of the first NUL byte, or else <[size]> if <[buf]> was
provided.

When reading, NUL bytes have no significance, and reads cannot exceed
the current file size.  When writing, the file size can increase up to
<[size]> as needed, and NUL bytes may be embedded in the stream (see
<<open_memstream>> for an alternative that automatically enlarges the
buffer).  When the stream is flushed or closed after a write that
changed the file size, a NUL byte is written at the current position
if there is still room; if the stream is not also open for reading, a
NUL byte is additionally written at the last byte of <[buf]> when the
stream has exceeded <[size]>, so that a write-only <[buf]> is always
NUL-terminated when the stream is flushed or closed (and the initial
<[size]> should take this into account).  It is not possible to seek
outside the bounds of <[size]>.  A NUL byte written during a flush is
restored to its previous value when seeking elsewhere in the string.

RETURNS
The return value is an open FILE pointer on success.  On error,
<<NULL>> is returned, and <<errno>> will be set to EINVAL if <[size]>
is zero or <[mode]> is invalid, ENOMEM if <[buf]> was NULL and memory
could not be allocated, or EMFILE if too many streams are already
open.

PORTABILITY
This function is being added to POSIX 200x, but is not in POSIX 2001.

Supporting OS subroutines required: <<sbrk>>.
*/

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/lock.h>
#include "local.h"

/* Describe details of an open memstream.  */
typedef struct fmemcookie {
  void *storage; /* storage to free on close */
  char *buf; /* buffer start */
  size_t pos; /* current position */
  size_t eof; /* current file size */
  size_t max; /* maximum file size */
  char append; /* nonzero if appending */
  char writeonly; /* 1 if write-only */
  char saved; /* saved character that lived at pos before write-only NUL */
} fmemcookie;

/* Read up to non-zero N bytes into BUF from stream described by
   COOKIE; return number of bytes read (0 on EOF).  */
static _READ_WRITE_RETURN_TYPE
_DEFUN(fmemreader, (ptr, cookie, buf, n),
       struct _reent *ptr _AND
       void *cookie _AND
       char *buf _AND
       int n)
{
  fmemcookie *c = (fmemcookie *) cookie;
  /* Can't read beyond current size, but EOF condition is not an error.  */
  if (c->pos > c->eof)
    return 0;
  if (n >= c->eof - c->pos)
    n = c->eof - c->pos;
  memcpy (buf, c->buf + c->pos, n);
  c->pos += n;
  return n;
}

/* Write up to non-zero N bytes of BUF into the stream described by COOKIE,
   returning the number of bytes written or EOF on failure.  */
static _READ_WRITE_RETURN_TYPE
_DEFUN(fmemwriter, (ptr, cookie, buf, n),
       struct _reent *ptr _AND
       void *cookie _AND
       const char *buf _AND
       int n)
{
  fmemcookie *c = (fmemcookie *) cookie;
  int adjust = 0; /* true if at EOF, but still need to write NUL.  */

  /* Append always seeks to eof; otherwise, if we have previously done
     a seek beyond eof, ensure all intermediate bytes are NUL.  */
  if (c->append)
    c->pos = c->eof;
  else if (c->pos > c->eof)
    memset (c->buf + c->eof, '\0', c->pos - c->eof);
  /* Do not write beyond EOF; saving room for NUL on write-only stream.  */
  if (c->pos + n > c->max - c->writeonly)
    {
      adjust = c->writeonly;
      n = c->max - c->pos;
    }
  /* Now n is the number of bytes being modified, and adjust is 1 if
     the last byte is NUL instead of from buf.  Write a NUL if
     write-only; or if read-write, eof changed, and there is still
     room.  When we are within the file contents, remember what we
     overwrite so we can restore it if we seek elsewhere later.  */
  if (c->pos + n > c->eof)
    {
      c->eof = c->pos + n;
      if (c->eof - adjust < c->max)
	c->saved = c->buf[c->eof - adjust] = '\0';
    }
  else if (c->writeonly)
    {
      if (n)
	{
	  c->saved = c->buf[c->pos + n - adjust];
	  c->buf[c->pos + n - adjust] = '\0';
	}
      else
	adjust = 0;
    }
  c->pos += n;
  if (n - adjust)
    memcpy (c->buf + c->pos - n, buf, n - adjust);
  else
    {
      ptr->_errno = ENOSPC;
      return EOF;
    }
  return n;
}

/* Seek to position POS relative to WHENCE within stream described by
   COOKIE; return resulting position or fail with EOF.  */
static _fpos_t
_DEFUN(fmemseeker, (ptr, cookie, pos, whence),
       struct _reent *ptr _AND
       void *cookie _AND
       _fpos_t pos _AND
       int whence)
{
  fmemcookie *c = (fmemcookie *) cookie;
#ifndef __LARGE64_FILES
  off_t offset = (off_t) pos;
#else /* __LARGE64_FILES */
  _off64_t offset = (_off64_t) pos;
#endif /* __LARGE64_FILES */

  if (whence == SEEK_CUR)
    offset += c->pos;
  else if (whence == SEEK_END)
    offset += c->eof;
  if (offset < 0)
    {
      ptr->_errno = EINVAL;
      offset = -1;
    }
  else if (offset > c->max)
    {
      ptr->_errno = ENOSPC;
      offset = -1;
    }
#ifdef __LARGE64_FILES
  else if ((_fpos_t) offset != offset)
    {
      ptr->_errno = EOVERFLOW;
      offset = -1;
    }
#endif /* __LARGE64_FILES */
  else
    {
      if (c->writeonly && c->pos < c->eof)
	{
	  c->buf[c->pos] = c->saved;
	  c->saved = '\0';
	}
      c->pos = offset;
      if (c->writeonly && c->pos < c->eof)
	{
	  c->saved = c->buf[c->pos];
	  c->buf[c->pos] = '\0';
	}
    }
  return (_fpos_t) offset;
}

/* Seek to position POS relative to WHENCE within stream described by
   COOKIE; return resulting position or fail with EOF.  */
#ifdef __LARGE64_FILES
static _fpos64_t
_DEFUN(fmemseeker64, (ptr, cookie, pos, whence),
       struct _reent *ptr _AND
       void *cookie _AND
       _fpos64_t pos _AND
       int whence)
{
  _off64_t offset = (_off64_t) pos;
  fmemcookie *c = (fmemcookie *) cookie;
  if (whence == SEEK_CUR)
    offset += c->pos;
  else if (whence == SEEK_END)
    offset += c->eof;
  if (offset < 0)
    {
      ptr->_errno = EINVAL;
      offset = -1;
    }
  else if (offset > c->max)
    {
      ptr->_errno = ENOSPC;
      offset = -1;
    }
  else
    {
      if (c->writeonly && c->pos < c->eof)
	{
	  c->buf[c->pos] = c->saved;
	  c->saved = '\0';
	}
      c->pos = offset;
      if (c->writeonly && c->pos < c->eof)
	{
	  c->saved = c->buf[c->pos];
	  c->buf[c->pos] = '\0';
	}
    }
  return (_fpos64_t) offset;
}
#endif /* __LARGE64_FILES */

/* Reclaim resources used by stream described by COOKIE.  */
static int
_DEFUN(fmemcloser, (ptr, cookie),
       struct _reent *ptr _AND
       void *cookie)
{
  fmemcookie *c = (fmemcookie *) cookie;
  _free_r (ptr, c->storage);
  return 0;
}

/* Open a memstream around buffer BUF of SIZE bytes, using MODE.
   Return the new stream, or fail with NULL.  */
FILE *
_DEFUN(_fmemopen_r, (ptr, buf, size, mode),
       struct _reent *ptr _AND
       void *buf _AND
       size_t size _AND
       const char *mode)
{
  FILE *fp;
  fmemcookie *c;
  int flags;
  int dummy;

  if ((flags = __sflags (ptr, mode, &dummy)) == 0)
    return NULL;
  if (!size || !(buf || flags & __SAPP))
    {
      ptr->_errno = EINVAL;
      return NULL;
    }
  if ((fp = __sfp (ptr)) == NULL)
    return NULL;
  if ((c = (fmemcookie *) _malloc_r (ptr, sizeof *c + (buf ? 0 : size)))
      == NULL)
    {
      __sfp_lock_acquire ();
      fp->_flags = 0;		/* release */
#ifndef __SINGLE_THREAD__
      __lock_close_recursive (fp->_lock);
#endif
      __sfp_lock_release ();
      return NULL;
    }

  c->storage = c;
  c->max = size;
  /* 9 modes to worry about.  */
  /* w/a, buf or no buf: Guarantee a NUL after any file writes.  */
  c->writeonly = (flags & __SWR) != 0;
  c->saved = '\0';
  if (!buf)
    {
      /* r+/w+/a+, and no buf: file starts empty.  */
      c->buf = (char *) (c + 1);
      *(char *) buf = '\0';
      c->pos = c->eof = 0;
      c->append = (flags & __SAPP) != 0;
    }
  else
    {
      c->buf = (char *) buf;
      switch (*mode)
	{
	case 'a':
	  /* a/a+ and buf: position and size at first NUL.  */
	  buf = memchr (c->buf, '\0', size);
	  c->eof = c->pos = buf ? (char *) buf - c->buf : size;
	  if (!buf && c->writeonly)
	    /* a: guarantee a NUL within size even if no writes.  */
	    c->buf[size - 1] = '\0';
	  c->append = 1;
	  break;
	case 'r':
	  /* r/r+ and buf: read at beginning, full size available.  */
	  c->pos = c->append = 0;
	  c->eof = size;
	  break;
	case 'w':
	  /* w/w+ and buf: write at beginning, truncate to empty.  */
	  c->pos = c->append = c->eof = 0;
	  *c->buf = '\0';
	  break;
	default:
	  abort ();
	}
    }

  _flockfile (fp);
  fp->_file = -1;
  fp->_flags = flags;
  fp->_cookie = c;
  fp->_read = flags & (__SRD | __SRW) ? fmemreader : NULL;
  fp->_write = flags & (__SWR | __SRW) ? fmemwriter : NULL;
  fp->_seek = fmemseeker;
#ifdef __LARGE64_FILES
  fp->_seek64 = fmemseeker64;
  fp->_flags |= __SL64;
#endif
  fp->_close = fmemcloser;
  _funlockfile (fp);
  return fp;
}

#ifndef _REENT_ONLY
FILE *
_DEFUN(fmemopen, (buf, size, mode),
       void *buf _AND
       size_t size _AND
       const char *mode)
{
  return _fmemopen_r (_REENT, buf, size, mode);
}
#endif /* !_REENT_ONLY */

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
/* No user fns here.  Pesch 15apr92. */

#include <_ansi.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include "local.h"
#include "fvwrite.h"

#define	MIN(a, b) ((a) < (b) ? (a) : (b))
#define	COPY(n)	  _CAST_VOID memmove ((_PTR) fp->_p, (_PTR) p, (size_t) (n))

#define GETIOV(extra_work) \
  while (len == 0) \
    { \
      extra_work; \
      p = iov->iov_base; \
      len = iov->iov_len; \
      iov++; \
    }

/*
 * Write some memory regions.  Return zero on success, EOF on error.
 *
 * This routine is large and unsightly, but most of the ugliness due
 * to the three different kinds of output buffering is handled here.
 */

int
_DEFUN(__sfvwrite_r, (ptr, fp, uio),
       struct _reent *ptr _AND
       register FILE *fp _AND
       register struct __suio *uio)
{
  register size_t len;
  register _CONST char *p = NULL;
  register struct __siov *iov;
  register int w, s;
  char *nl;
  int nlknown, nldist;

  if ((len = uio->uio_resid) == 0)
    return 0;

  /* make sure we can write */
  if (cantwrite (ptr, fp))
    {
      fp->_flags |= __SERR;
      ptr->_errno = EBADF;
      return EOF;
    }

  iov = uio->uio_iov;
  len = 0;

#ifdef __SCLE
  if (fp->_flags & __SCLE) /* text mode */
    {
      do
        {
          GETIOV (;);
          while (len > 0)
            {
              if (putc (*p, fp) == EOF)
                return EOF;
              p++;
              len--;
              uio->uio_resid--;
            }
        }
      while (uio->uio_resid > 0);
      return 0;
    }
#endif

  if (fp->_flags & __SNBF)
    {
      /*
       * Unbuffered: write up to BUFSIZ bytes at a time.
       */
      do
	{
	  GETIOV (;);
	  w = fp->_write (ptr, fp->_cookie, p, MIN (len, BUFSIZ));
	  if (w <= 0)
	    goto err;
	  p += w;
	  len -= w;
	}
      while ((uio->uio_resid -= w) != 0);
    }
  else if ((fp->_flags & __SLBF) == 0)
    {
      /*
       * Fully buffered: fill partially full buffer, if any,
       * and then flush.  If there is no partial buffer, write
       * one _bf._size byte chunk directly (without copying).
       *
       * String output is a special case: write as many bytes
       * as fit, but pretend we wrote everything.  This makes
       * snprintf() return the number of bytes needed, rather
       * than the number used, and avoids its write function
       * (so that the write function can be invalid).  If
       * we are dealing with the asprintf routines, we will
       * dynamically increase the buffer size as needed.
       */
      do
	{
	  GETIOV (;);
	  w = fp->_w;
	  if (fp->_flags & __SSTR)
	    {
	      if (len >= w && fp->_flags & (__SMBF | __SOPT))
		{ /* must be asprintf family */
		  unsigned char *str;
		  int curpos = (fp->_p - fp->_bf._base);
		  /* Choose a geometric growth factor to avoid
		     quadratic realloc behavior, but use a rate less
		     than (1+sqrt(5))/2 to accomodate malloc
		     overhead. asprintf EXPECTS us to overallocate, so
		     that it can add a trailing \0 without
		     reallocating.  The new allocation should thus be
		     max(prev_size*1.5, curpos+len+1). */
		  int newsize = fp->_bf._size * 3 / 2;
		  if (newsize < curpos + len + 1)
		    newsize = curpos + len + 1;
		  if (fp->_flags & __SOPT)
		    {
		      /* asnprintf leaves original buffer alone.  */
		      str = (unsigned char *)_malloc_r (ptr, newsize);
		      if (!str)
			{
			  ptr->_errno = ENOMEM;
			  goto err;
			}
		      memcpy (str, fp->_bf._base, curpos);
		      fp->_flags = (fp->_flags & ~__SOPT) | __SMBF;
		    }
		  else
		    {
		      str = (unsigned char *)_realloc_r (ptr, fp->_bf._base,
							 newsize);
		      if (!str)
			{
			  /* Free buffer which is no longer used.  */
			  _free_r (ptr, fp->_bf._base);
			  /* Ensure correct errno, even if free changed it.  */
			  ptr->_errno = ENOMEM;
			  goto err;
			}
		    }
		  fp->_bf._base = str;
		  fp->_p = str + curpos;
		  fp->_bf._size = newsize;
		  w = len;
		  fp->_w = newsize - curpos;
		}
	      if (len < w)
		w = len;
	      COPY (w);		/* copy MIN(fp->_w,len), */
	      fp->_w -= w;
	      fp->_p += w;
	      w = len;		/* but pretend copied all */
	    }
	  else if (fp->_p > fp->_bf._base && len > w)
	    {
	      /* fill and flush */
	      COPY (w);
	      /* fp->_w -= w; *//* unneeded */
	      fp->_p += w;
	      if (_fflush_r (ptr, fp))
		goto err;
	    }
	  else if (len >= (w = fp->_bf._size))
	    {
	      /* write directly */
	      w = fp->_write (ptr, fp->_cookie, p, w);
	      if (w <= 0)
		goto err;
	    }
	  else
	    {
	      /* fill and done */
	      w = len;
	      COPY (w);
	      fp->_w -= w;
	      fp->_p += w;
	    }
	  p += w;
	  len -= w;
	}
      while ((uio->uio_resid -= w) != 0);
    }
  else
    {
      /*
       * Line buffered: like fully buffered, but we
       * must check for newlines.  Compute the distance
       * to the first newline (including the newline),
       * or `infinity' if there is none, then pretend
       * that the amount to write is MIN(len,nldist).
       */
      nlknown = 0;
      nldist = 0;
      do
	{
	  GETIOV (nlknown = 0);
	  if (!nlknown)
	    {
	      nl = memchr ((_PTR) p, '\n', len);
	      nldist = nl ? nl + 1 - p : len + 1;
	      nlknown = 1;
	    }
	  s = MIN (len, nldist);
	  w = fp->_w + fp->_bf._size;
	  if (fp->_p > fp->_bf._base && s > w)
	    {
	      COPY (w);
	      /* fp->_w -= w; */
	      fp->_p += w;
	      if (_fflush_r (ptr, fp))
		goto err;
	    }
	  else if (s >= (w = fp->_bf._size))
	    {
	      w = fp->_write (ptr, fp->_cookie, p, w);
	      if (w <= 0)
		goto err;
	    }
	  else
	    {
	      w = s;
	      COPY (w);
	      fp->_w -= w;
	      fp->_p += w;
	    }
	  if ((nldist -= w) == 0)
	    {
	      /* copied the newline: flush and forget */
	      if (_fflush_r (ptr, fp))
		goto err;
	      nlknown = 0;
	    }
	  p += w;
	  len -= w;
	}
      while ((uio->uio_resid -= w) != 0);
    }
  return 0;

err:
  fp->_flags |= __SERR;
  return EOF;
}

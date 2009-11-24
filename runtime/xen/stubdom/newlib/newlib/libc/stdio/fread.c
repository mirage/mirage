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

/*
FUNCTION
<<fread>>---read array elements from a file

INDEX
	fread
INDEX
	_fread_r

ANSI_SYNOPSIS
	#include <stdio.h>
	size_t fread(void *<[buf]>, size_t <[size]>, size_t <[count]>,
		     FILE *<[fp]>);

	#include <stdio.h>
	size_t _fread_r(struct _reent *<[ptr]>, void *<[buf]>,
	                size_t <[size]>, size_t <[count]>,
		        FILE *<[fp]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	size_t fread(<[buf]>, <[size]>, <[count]>, <[fp]>)
	char *<[buf]>;
	size_t <[size]>;
	size_t <[count]>;
	FILE *<[fp]>;

	#include <stdio.h>
	size_t _fread_r(<[ptr]>, <[buf]>, <[size]>, <[count]>, <[fp]>)
	struct _reent *<[ptr]>;
	char *<[buf]>;
	size_t <[size]>;
	size_t <[count]>;
	FILE *<[fp]>;

DESCRIPTION
<<fread>> attempts to copy, from the file or stream identified by
<[fp]>, <[count]> elements (each of size <[size]>) into memory,
starting at <[buf]>.   <<fread>> may copy fewer elements than
<[count]> if an error, or end of file, intervenes.

<<fread>> also advances the file position indicator (if any) for
<[fp]> by the number of @emph{characters} actually read.

<<_fread_r>> is simply the reentrant version of <<fread>> that
takes an additional reentrant structure pointer argument: <[ptr]>.

RETURNS
The result of <<fread>> is the number of elements it succeeded in
reading.

PORTABILITY
ANSI C requires <<fread>>.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include "local.h"

#ifdef __SCLE
static size_t
_DEFUN(crlf_r, (ptr, fp, buf, count, eof),
       struct _reent * ptr _AND
       FILE * fp _AND
       char * buf _AND
       size_t count _AND
       int eof)
{
  int newcount = 0, r;
  char *s, *d, *e;

  if (count == 0)
    return 0;

  e = buf + count;
  for (s=d=buf; s<e-1; s++)
    {
      if (*s == '\r' && s[1] == '\n')
        s++;
      *d++ = *s;
    }
  if (s < e)
    {
      if (*s == '\r')
        {
          int c = __sgetc_raw_r (ptr, fp);
          if (c == '\n')
            *s = '\n';
          else
            ungetc (c, fp);
        }
      *d++ = *s++;
    }


  while (d < e)
    {
      r = _getc_r (ptr, fp);
      if (r == EOF)
        return count - (e-d);
      *d++ = r;
    }

  return count;
  
}

#endif

size_t
_DEFUN(_fread_r, (ptr, buf, size, count, fp),
       struct _reent * ptr _AND
       _PTR buf _AND
       size_t size _AND
       size_t count _AND
       FILE * fp)
{
  register size_t resid;
  register char *p;
  register int r;
  size_t total;

  if ((resid = count * size) == 0)
    return 0;

  CHECK_INIT(ptr, fp);

  _flockfile (fp);
  if (fp->_r < 0)
    fp->_r = 0;
  total = resid;
  p = buf;

#if !defined(PREFER_SIZE_OVER_SPEED) && !defined(__OPTIMIZE_SIZE__)

  /* Optimize unbuffered I/O.  */
  if (fp->_flags & __SNBF)
    {
      /* First copy any available characters from ungetc buffer.  */
      int copy_size = resid > fp->_r ? fp->_r : resid;
      _CAST_VOID memcpy ((_PTR) p, (_PTR) fp->_p, (size_t) copy_size);
      fp->_p += copy_size;
      fp->_r -= copy_size;
      p += copy_size;
      resid -= copy_size;

      /* If still more data needed, free any allocated ungetc buffer.  */
      if (HASUB (fp) && resid > 0)
	FREEUB (ptr, fp);

      /* Finally read directly into user's buffer if needed.  */
      while (resid > 0)
	{
	  int rc = 0;
	  /* save fp buffering state */
	  void *old_base = fp->_bf._base;
	  void * old_p = fp->_p;
	  int old_size = fp->_bf._size;
	  /* allow __refill to use user's buffer */
	  fp->_bf._base = p;
	  fp->_bf._size = resid;
	  fp->_p = p;
	  rc = __srefill_r (ptr, fp);
	  /* restore fp buffering back to original state */
	  fp->_bf._base = old_base;
	  fp->_bf._size = old_size;
	  fp->_p = old_p;
	  resid -= fp->_r;
	  p += fp->_r;
	  fp->_r = 0;
	  if (rc)
	    {
#ifdef __SCLE
              if (fp->_flags & __SCLE)
	        {
	          _funlockfile (fp);
	          return crlf_r (ptr, fp, buf, total-resid, 1) / size;
	        }
#endif
	      _funlockfile (fp);
	      return (total - resid) / size;
	    }
	}
    }
  else
#endif /* !PREFER_SIZE_OVER_SPEED && !__OPTIMIZE_SIZE__ */
    {
      while (resid > (r = fp->_r))
	{
	  _CAST_VOID memcpy ((_PTR) p, (_PTR) fp->_p, (size_t) r);
	  fp->_p += r;
	  /* fp->_r = 0 ... done in __srefill */
	  p += r;
	  resid -= r;
	  if (__srefill_r (ptr, fp))
	    {
	      /* no more input: return partial result */
#ifdef __SCLE
	      if (fp->_flags & __SCLE)
		{
		  _funlockfile (fp);
		  return crlf_r (ptr, fp, buf, total-resid, 1) / size;
		}
#endif
	      _funlockfile (fp);
	      return (total - resid) / size;
	    }
	}
      _CAST_VOID memcpy ((_PTR) p, (_PTR) fp->_p, resid);
      fp->_r -= resid;
      fp->_p += resid;
    }

  /* Perform any CR/LF clean-up if necessary.  */
#ifdef __SCLE
  if (fp->_flags & __SCLE)
    {
      _funlockfile (fp);
      return crlf_r(ptr, fp, buf, total, 0) / size;
    }
#endif
  _funlockfile (fp);
  return count;
}

#ifndef _REENT_ONLY
size_t
_DEFUN(fread, (buf, size, count, fp),
       _PTR buf _AND
       size_t size _AND
       size_t count _AND
       FILE * fp)
{
   return _fread_r (_REENT, buf, size, count, fp);
}
#endif

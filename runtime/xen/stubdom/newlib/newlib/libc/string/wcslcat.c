/*
FUNCTION
	<<wcslcat>>---concatenate wide-character strings to specified length

ANSI_SYNOPSIS
	#include <wchar.h>
	size_t wcslcat(wchar_t *<[dst]>, const wchar_t *<[src]>, size_t <[siz]>);

TRAD_SYNOPSIS
	#include <wchar.h>
	size_t wcslcat(<[dst]>, <[src]>, <[siz]>
	wchar_t *<[dst]>;
	const wchar_t *<[src]>;
	size_t <[siz]>;

DESCRIPTION
	The <<wcslcat>> function appends wide characters from <[src]> to
	end of the <[dst]> wide-character string so that the resultant
	wide-character string is not more than <[siz]> wide characters
	including the terminating null wide-character code.  A terminating
	null wide character is always added unless <[siz]> is 0.  Thus,
	the maximum number of wide characters that can be appended from
	<[src]> is <[siz]> - 1. If copying takes place between objects 
	that overlap, the behaviour is undefined.

RETURNS
	Wide-character string length of initial <[dst]> plus the
	wide-character string length of <[src]> (does not include
	terminating null wide-characters).  If the return value is
	greater than or equal to <[siz]>, then truncation occurred and
	not all wide characters from <[src]> were appended.

PORTABILITY
No supporting OS subroutines are required.
*/

/*	$NetBSD: wcslcat.c,v 1.1 2000/12/23 23:14:36 itojun Exp $	*/
/*	from OpenBSD: strlcat.c,v 1.3 2000/11/24 11:10:02 itojun Exp 	*/

/*
 * Copyright (c) 1998 Todd C. Miller <Todd.Miller@courtesan.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <_ansi.h>
#include <wchar.h>

/*
 * Appends src to string dst of size siz (unlike wcsncat, siz is the
 * full size of dst, not space left).  At most siz-1 characters
 * will be copied.  Always NUL terminates (unless siz == 0).
 * Returns wcslen(initial dst) + wcslen(src); if retval >= siz,
 * truncation occurred.
 */
size_t
_DEFUN (wcslcat, (dst, src, siz),
	wchar_t * dst _AND
	_CONST wchar_t * src _AND
	size_t siz)
{
  wchar_t *d = dst;
  _CONST wchar_t *s = src;
  size_t n = siz;
  size_t dlen;

  /* Find the end of dst and adjust bytes left but don't go past end */
  while (*d != '\0' && n-- != 0)
    d++;
  dlen = d - dst;
  n = siz - dlen;

  if (n == 0)
    return (dlen + wcslen (s));
  while (*s != '\0')
    {
      if (n != 1)
	{
	  *d++ = *s;
	  n--;
	}
      s++;
    }
  *d = '\0';

  return (dlen + (s - src));	/* count does not include NUL */
}

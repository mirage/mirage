/*
FUNCTION
	<<wcslcpy>>---copy a wide-character string to specified length

ANSI_SYNOPSIS
	#include <wchar.h>
	size_t wcslcpy(wchar_t *<[dst]>, const wchar_t *<[src]>, size_t <[siz]>);

TRAD_SYNOPSIS
	#include <wchar.h>
	size_t wcslcpy(<[dst]>, <[src]>, <[siz]>)
	wchar_t *<[dst]>;
	const wchar_t *<[src]>;
	size_t <[siz]>;

DESCRIPTION
	<<wcslcpy>> copies wide characters from <[src]> to <[dst]>
	such that up to <[siz]> - 1 characters are copied.  A
	terminating null is appended to the result, unless <[siz]>
	is zero.

RETURNS
	<<wcslcpy>> returns the number of wide characters in <[src]>,
	not including the terminating null wide character.  If the
	return value is greater than or equal to <[siz]>, then
	not all wide characters were copied from <[src]> and truncation
	occurred.

PORTABILITY
No supporting OS subroutines are required.
*/

/*	$NetBSD: wcslcpy.c,v 1.1 2000/12/23 23:14:36 itojun Exp $	*/
/*	from OpenBSD: strlcpy.c,v 1.4 1999/05/01 18:56:41 millert Exp 	*/

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
 * Copy src to string dst of size siz.  At most siz-1 characters
 * will be copied.  Always NUL terminates (unless siz == 0).
 * Returns wcslen(src); if retval >= siz, truncation occurred.
 */
size_t
_DEFUN (wcslcpy, (dst, src, siz),
	wchar_t * dst _AND
	_CONST wchar_t * src _AND
	size_t siz)
{
  wchar_t *d = dst;
  _CONST wchar_t *s = src;
  size_t n = siz;

  /* Copy as many bytes as will fit */
  if (n != 0 && --n != 0)
    {
      do
	{
	  if ((*d++ = *s++) == 0)
	    break;
	}
      while (--n != 0);
    }

  /* Not enough room in dst, add NUL and traverse rest of src */
  if (n == 0)
    {
      if (siz != 0)
	*d = '\0';		/* NUL-terminate dst */
      while (*s++)
	;
    }

  return (s - src - 1);		/* count does not include NUL */
}

/*
FUNCTION
	<<wcsstr>>---find a wide-character substring 

ANSI_SYNOPSIS
	#include <wchar.h>
	wchar_t *wcsstr(const wchar_t *<[big]>, const wchar_t *<[little]>);

TRAD_SYNOPSIS
	wchar_t *wcsstr(<[big]>, <[little]>
	const wchar_t *<[big]>;
	const wchar_t *<[little]>;

DESCRIPTION
	The <<wcsstr>> function locates the first occurrence in the
	wide-character string pointed to by <[big]> of the sequence of
	wide characters (excluding the terminating null wide character) in the
	wide-character string pointed to by <[little]>.

RETURNS
	On successful completion, <<wcsstr>> returns a pointer to the located
	wide-character string, or a null pointer if the wide-character string
	is not found.

	If <[little]> points to a wide-character string with zero length,
	the function returns <[big]>.

PORTABILITY
<<wcsstr>> is ISO/IEC 9899/AMD1:1995 (ISO C).

*/

/*	$NetBSD: wcsstr.c,v 1.1 2000/12/23 23:14:37 itojun Exp $	*/

/*-
 * Copyright (c)1999 Citrus Project,
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
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	citrus Id: wcsstr.c,v 1.2 2000/12/21 05:07:25 itojun Exp
 */

#include <_ansi.h>
#include <stddef.h>
#include <wchar.h>

wchar_t *
_DEFUN (wcsstr, (big, little),
	_CONST wchar_t * big _AND
	_CONST wchar_t * little)
{
  _CONST wchar_t *p;
  _CONST wchar_t *q;
  _CONST wchar_t *r;

  if (!*little)
    {
      /* LINTED interface specification */
      return (wchar_t *) big;
    }
  if (wcslen (big) < wcslen (little))
    return NULL;

  p = big;
  q = little;
  while (*p)
    {
      q = little;
      r = p;
      while (*q)
	{
	  if (*r != *q)
	    break;
	  q++;
	  r++;
	}
      if (!*q)
	{
	  /* LINTED interface specification */
	  return (wchar_t *) p;
	}
      p++;
    }
  return NULL;
}

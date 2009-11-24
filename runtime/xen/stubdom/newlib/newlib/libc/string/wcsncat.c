/*
FUNCTION
	<<wcsncat>>---concatenate part of two wide-character strings 

ANSI_SYNOPSIS
	#include <wchar.h>
	wchar_t *wcsncat(wchar_t *<[s1]>, const wchar_t *<[s2]>, size_t <[n]>);

TRAD_SYNOPSIS
	wchar_t *wcsncat(<[s1]>, <[s2]>, <[n]>
	wchar_t *<[s1]>;
	const wchar_t *<[s2]>;
	size_t <[n]>;

DESCRIPTION
	The <<wcsncat>> function appends not more than <[n]> wide-character
	codes (a null wide-character code and wide-character codes that follow
	it are not appended) from the array pointed to by <[s2]> to the end of
	the wide-character string pointed to by <[s1]>. The initial
	wide-character code of <[s2]> overwrites the null wide-character code
	at the end of <[s1]>.
	A terminating null wide-character code is always appended to the result.
	If copying takes place between objects that overlap, the behaviour is
	undefined.

RETURNS
	The <<wcsncat>> function returns <[s1]>; no return value is reserved to
	indicate an error.

PORTABILITY
<<wcsncat>> is ISO/IEC 9899/AMD1:1995 (ISO C).

No supporting OS subroutines are required.
*/

/*	$NetBSD: wcsncat.c,v 1.1 2000/12/23 23:14:36 itojun Exp $	*/

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
 *	citrus Id: wcsncat.c,v 1.1 1999/12/29 21:47:45 tshiozak Exp
 */

#include <_ansi.h>
#include <wchar.h>

wchar_t *
_DEFUN (wcsncat, (s1, s2, n),
	wchar_t * s1 _AND
	_CONST wchar_t * s2 _AND
	size_t n)
{
  wchar_t *p;
  wchar_t *q;
  _CONST wchar_t *r;

  p = s1;
  while (*p)
    p++;
  q = p;
  r = s2;
  while (*r && n)
    {
      *q++ = *r++;
      n--;
    }
  *q = '\0';
  return s1;
}

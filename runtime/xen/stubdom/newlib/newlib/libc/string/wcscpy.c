/*
FUNCTION
	<<wcscpy>>---copy a wide-character string 

ANSI_SYNOPSIS
	#include <wchar.h>
	wchar_t *wcscpy(wchar_t *<[s1]>, const wchar_t *,<[s2]>);

TRAD_SYNOPSIS
	wchar_t *wcscpy(<[s1]>, <[s2]>
	wchar_t *<[s1]>;
	const wchar_t *<[s2]>;

DESCRIPTION
	The <<wcscpy>> function copies the wide-character string pointed to by
	<[s2]> (including the terminating null wide-character code) into the
	array pointed to by <[s1]>. If copying takes place between objects that
	overlap, the behaviour is undefined. 

RETURNS
	The <<wcscpy>> function returns <[s1]>; no return value is reserved to
	indicate an error. 

PORTABILITY
<<wcscpy>> is ISO/IEC 9899/AMD1:1995 (ISO C).

No supporting OS subroutines are required.
*/

/*	$NetBSD: wcscpy.c,v 1.1 2000/12/23 23:14:36 itojun Exp $	*/

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
 *	citrus Id: wcscpy.c,v 1.2 2000/12/21 04:51:09 itojun Exp
 */

#include <_ansi.h>
#include <wchar.h>

wchar_t *
_DEFUN (wcscpy, (s1, s2),
	wchar_t * s1 _AND
	_CONST wchar_t * s2)
{
  wchar_t *p;
  _CONST wchar_t *q;

  *s1 = '\0';
  p = s1;
  q = s2;
  while (*q)
    *p++ = *q++;
  *p = '\0';

  return s1;
}

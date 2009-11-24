/*
FUNCTION
	<<wcsrchr>>---wide-character string scanning operation 

ANSI_SYNOPSIS
	#include <wchar.h>
	wchar_t *wcsrchr(const wchar_t *<[s]>, wchar_t <[c]>);

TRAD_SYNOPSIS
	#include <wchar.h>
	wchar_t *wcsrchr(<[s]>, <[c]>
	const wchar_t *<[s]>;
	wchar_t <[c]>;

DESCRIPTION
	The <<wcsrchr>> function locates the last occurrence of <[c]> in the
	wide-character string pointed to by <[s]>. The value of <[c]> must be a
	character representable as a type wchar_t and must be a wide-character
	code corresponding to a valid character in the current locale.
	The terminating null wide-character code is considered to be part of
	the wide-character string. 

RETURNS
	Upon successful completion, <<wcsrchr>> returns a pointer to the
	wide-character code or a null pointer if <[c]> does not occur in the
	wide-character string.

PORTABILITY
<<wcsrchr>> is ISO/IEC 9899/AMD1:1995 (ISO C).

No supporting OS subroutines are required.
*/

/*	$NetBSD: wcsrchr.c,v 1.1 2000/12/23 23:14:37 itojun Exp $	*/

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
 *	citrus Id: wcsrchr.c,v 1.2 2000/12/21 05:07:25 itojun Exp
 */

#include <_ansi.h>
#include <stddef.h>
#include <wchar.h>

wchar_t *
_DEFUN (wcsrchr, (s, c),
	_CONST wchar_t * s _AND
	wchar_t c)
{
  _CONST wchar_t *p;

  p = s;
  while (*p)
    p++;
  while (s <= p)
    {
      if (*p == c)
	{
	  /* LINTED interface specification */
	  return (wchar_t *) p;
	}
      p--;
    }
  return NULL;
}

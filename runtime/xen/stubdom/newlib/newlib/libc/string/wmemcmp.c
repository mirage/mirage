/*
FUNCTION
	<<wmemcmp>>---compare wide characters in memory 

ANSI_SYNOPSIS
	#include <wchar.h>
	int wmemcmp(const wchar_t *<[s1]>, const wchar_t *<[s2]>, size_t <[n]>);

TRAD_SYNOPSIS
	int wmemcmp(<[s1]>, <[s2]>, <[n]>
	const wchar_t *<[s1]>;
	const wchar_t *<[s2]>;
	size_t <[n]>;

DESCRIPTION
	The <<wmemcmp>> function compares the first <[n]> wide characters of the
	object pointed to by <[s1]> to the first <[n]> wide characters of the
	object pointed to by <[s2]>. This function is not affected by locale
	and all wchar_t values are treated identically. The null wide character
	and wchar_t values not corresponding to valid characters are not treated
	specially.

	If <[n]> is zero, <[s1]> and <[s2]> must be a valid pointers and the
	function behaves as if the two objects compare equal. 

RETURNS
	The <<wmemcmp>> function returns an integer greater than, equal to,
	or less than zero, accordingly as the object pointed to by <[s1]> is
	greater than, equal to, or less than the object pointed to by <[s2]>.

PORTABILITY
<<wmemcmp>> is ISO/IEC 9899/AMD1:1995 (ISO C).

No supporting OS subroutines are required.
*/

/*	$NetBSD: wmemcmp.c,v 1.1 2000/12/23 23:14:37 itojun Exp $	*/

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
 *	citrus Id: wmemcmp.c,v 1.2 2000/12/20 14:08:31 itojun Exp
 */

#include <_ansi.h>
#include <wchar.h>

int
_DEFUN (wmemcmp, (s1, s2, n),
	_CONST wchar_t * s1 _AND
	_CONST wchar_t * s2 _AND
	size_t n)
{
  size_t i;

  for (i = 0; i < n; i++)
    {
      if (*s1 != *s2)
	{
	  /* wchar might be unsigned */
	  return *s1 > *s2 ? 1 : -1;
	}
      s1++;
      s2++;
    }
  return 0;
}

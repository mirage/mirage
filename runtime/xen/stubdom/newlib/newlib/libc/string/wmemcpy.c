/*
FUNCTION
	<<wmemcpy>>---copy wide characters in memory 

ANSI_SYNOPSIS
	#include <wchar.h>
	wchar_t *wmemcpy(wchar_t *<[d]>, const wchar_t *<[s]>, size_t <[n]>);

TRAD_SYNOPSIS
	wchar_t *wmemcpy(<[d]>, <[s]>, <[n]>
	wchar_t *<[d]>;
	const wchar_t *<[s]>;
	size_t <[n]>;

DESCRIPTION
	The <<wmemcpy>> function copies <[n]> wide characters from the object
	pointed to by <[s]> to the object pointed to be <[d]>. This function
	is not affected by locale and all wchar_t values are treated
	identically.  The null wide character and wchar_t values not
	corresponding to valid characters are not treated specially.

	If <[n]> is zero, <[d]> and <[s]> must be a valid pointers, and the
	function copies zero wide characters. 

RETURNS
	The <<wmemcpy>> function returns the value of <[d]>.

PORTABILITY
<<wmemcpy>> is ISO/IEC 9899/AMD1:1995 (ISO C).

No supporting OS subroutines are required.
*/

/*	$NetBSD: wmemcpy.c,v 1.1 2000/12/23 23:14:37 itojun Exp $	*/

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
 *	citrus Id: wmemcpy.c,v 1.2 2000/12/20 14:08:31 itojun Exp
 */

#include <_ansi.h>
#include <string.h>
#include <wchar.h>

wchar_t *
_DEFUN (wmemcpy, (d, s, n),
	wchar_t * d _AND
	_CONST wchar_t * s _AND
	size_t n)
{

  return (wchar_t *) memcpy (d, s, n * sizeof (wchar_t));
}

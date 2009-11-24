/*
FUNCTION
	<<wcspbrk>>----scan wide-character string for a wide-character code

ANSI_SYNOPSIS
	#include <wchar.h>
	wchar_t *wcspbrk(const wchar_t *<[s]>, const wchar_t *<[set]>);

TRAD_SYNOPSIS
	wchar_t *wcspbrk(<[s]>, <[set]>
	const wchar_t *<[s]>;
	const wchar_t *<[set]>;

DESCRIPTION
	The <<wcspbrk>> function locates the first occurrence in the
	wide-character string pointed to by <[s]> of any wide-character code
	from the wide-character string pointed to by <[set]>. 

RETURNS
	Upon successful completion, <<wcspbrk>> returns a pointer to the
	wide-character code or a null pointer if no wide-character code from
	<[set]> occurs in <[s]>.

PORTABILITY
<<wcspbrk>> is ISO/IEC 9899/AMD1:1995 (ISO C).

No supporting OS subroutines are required.
*/

/*	$NetBSD: wcspbrk.c,v 1.1 2000/12/23 23:14:37 itojun Exp $	*/

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
 *	citrus Id: wcspbrk.c,v 1.2 2000/12/21 05:07:25 itojun Exp
 */

#include <_ansi.h>
#include <stddef.h>
#include <wchar.h>

wchar_t *
_DEFUN (wcspbrk, (s, set),
	_CONST wchar_t * s _AND
	_CONST wchar_t * set)
{
  _CONST wchar_t *p;
  _CONST wchar_t *q;

  p = s;
  while (*p)
    {
      q = set;
      while (*q)
	{
	  if (*p == *q)
	    {
	      /* LINTED interface specification */
	      return (wchar_t *) p;
	    }
	  q++;
	}
      p++;
    }
  return NULL;
}

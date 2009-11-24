/*
FUNCTION
<<lldiv>>---divide two long long integers

INDEX
        lldiv

ANSI_SYNOPSIS
        #include <stdlib.h>
        lldiv_t lldiv(long long <[n]>, long long <[d]>);

TRAD_SYNOPSIS
        #include <stdlib.h>
        lldiv_t lldiv(<[n]>, <[d]>)
        long long <[n]>, <[d]>;

DESCRIPTION
Divide
@tex
$n/d$,
@end tex
@ifnottex
<[n]>/<[d]>,
@end ifnottex
returning quotient and remainder as two long long integers in a structure 
<<lldiv_t>>.

RETURNS
The result is represented with the structure

. typedef struct
. {
.  long long quot;
.  long long rem;
. } lldiv_t;

where the <<quot>> field represents the quotient, and <<rem>> the
remainder.  For nonzero <[d]>, if `<<<[r]> = ldiv(<[n]>,<[d]>);>>' then
<[n]> equals `<<<[r]>.rem + <[d]>*<[r]>.quot>>'.

To divide <<long>> rather than <<long long>> values, use the similar
function <<ldiv>>.

PORTABILITY
<<lldiv>> is ISO 9899 (C99) compatable.

No supporting OS subroutines are required.
*/

/*-
 * Copyright (c) 2001 Mike Barcroft <mike@FreeBSD.org>
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
 */

#include <stdlib.h>

/*
 * The ANSI standard says that |r.quot| <= |n/d|, where
 * n/d is to be computed in infinite precision.  In other
 * words, we should always truncate the quotient towards
 * 0, never -infinity.
 *
 * Machine division and remainer may work either way when
 * one or both of n or d is negative.  If only one is
 * negative and r.quot has been truncated towards -inf,
 * r.rem will have the same sign as denom and the opposite
 * sign of num; if both are negative and r.quot has been
 * truncated towards -inf, r.rem will be positive (will
 * have the opposite sign of num).  These are considered
 * `wrong'.
 *
 * If both are num and denom are positive, r will always
 * be positive.
 *
 * This all boils down to:
 *      if num >= 0, but r.rem < 0, we got the wrong answer.
 * In that case, to get the right answer, add 1 to r.quot and
 * subtract denom from r.rem.
 */
lldiv_t
_DEFUN (lldiv, (number, denom), 
       long long numer _AND long long denom)
{
	lldiv_t retval;

	retval.quot = numer / denom;
	retval.rem = numer % denom;
	if (numer >= 0 && retval.rem < 0) {
		retval.quot++;
		retval.rem -= denom;
	}
	return (retval);
}


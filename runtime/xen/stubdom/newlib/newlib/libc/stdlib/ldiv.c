/*
FUNCTION
<<ldiv>>---divide two long integers

INDEX
	ldiv

ANSI_SYNOPSIS
	#include <stdlib.h>
	ldiv_t ldiv(long <[n]>, long <[d]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	ldiv_t ldiv(<[n]>, <[d]>)
	long <[n]>, <[d]>;

DESCRIPTION
Divide
@tex
$n/d$,
@end tex
@ifnottex
<[n]>/<[d]>,
@end ifnottex
returning quotient and remainder as two long integers in a structure <<ldiv_t>>.

RETURNS
The result is represented with the structure

. typedef struct
. {
.  long quot;
.  long rem;
. } ldiv_t;

where the <<quot>> field represents the quotient, and <<rem>> the
remainder.  For nonzero <[d]>, if `<<<[r]> = ldiv(<[n]>,<[d]>);>>' then
<[n]> equals `<<<[r]>.rem + <[d]>*<[r]>.quot>>'.

To divide <<int>> rather than <<long>> values, use the similar
function <<div>>.

PORTABILITY
<<ldiv>> is ANSI.

No supporting OS subroutines are required.
*/


/*
 * Copyright (c) 1990 Regents of the University of California.
 * All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * Chris Torek.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <_ansi.h>
#include <stdlib.h>		/* ldiv_t */

ldiv_t
_DEFUN (ldiv, (num, denom),
        long num _AND
        long denom)
{
	ldiv_t r;

	/* see div.c for comments */

	r.quot = num / denom;
	r.rem = num % denom;
	if (num >= 0 && r.rem < 0) {
		++r.quot;
		r.rem -= denom;
	}
	else if (num < 0 && r.rem > 0) {
		--r.quot;
		r.rem += denom;
	}
	return (r);
}

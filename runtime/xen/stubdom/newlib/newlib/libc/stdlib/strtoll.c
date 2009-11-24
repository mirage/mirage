/*
FUNCTION
   <<strtoll>>---string to long long

INDEX
	strtoll
INDEX
	_strtoll_r

ANSI_SYNOPSIS
	#include <stdlib.h>
        long long strtoll(const char *<[s]>, char **<[ptr]>,int <[base]>);

        long long _strtoll_r(void *<[reent]>, 
                       const char *<[s]>, char **<[ptr]>,int <[base]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	long long strtoll (<[s]>, <[ptr]>, <[base]>)
        const char *<[s]>;
        char **<[ptr]>;
        int <[base]>;

	long long _strtoll_r (<[reent]>, <[s]>, <[ptr]>, <[base]>)
	char *<[reent]>;
        const char *<[s]>;
        char **<[ptr]>;
        int <[base]>;

DESCRIPTION
The function <<strtoll>> converts the string <<*<[s]>>> to
a <<long long>>. First, it breaks down the string into three parts:
leading whitespace, which is ignored; a subject string consisting
of characters resembling an integer in the radix specified by <[base]>;
and a trailing portion consisting of zero or more unparseable characters,
and always including the terminating null character. Then, it attempts
to convert the subject string into a <<long long>> and returns the
result.

If the value of <[base]> is 0, the subject string is expected to look
like a normal C integer constant: an optional sign, a possible `<<0x>>'
indicating a hexadecimal base, and a number. If <[base]> is between
2 and 36, the expected form of the subject is a sequence of letters
and digits representing an integer in the radix specified by <[base]>,
with an optional plus or minus sign. The letters <<a>>--<<z>> (or,
equivalently, <<A>>--<<Z>>) are used to signify values from 10 to 35;
only letters whose ascribed values are less than <[base]> are
permitted. If <[base]> is 16, a leading <<0x>> is permitted.

The subject sequence is the longest initial sequence of the input
string that has the expected form, starting with the first
non-whitespace character.  If the string is empty or consists entirely
of whitespace, or if the first non-whitespace character is not a
permissible letter or digit, the subject string is empty.

If the subject string is acceptable, and the value of <[base]> is zero,
<<strtoll>> attempts to determine the radix from the input string. A
string with a leading <<0x>> is treated as a hexadecimal value; a string with
a leading 0 and no <<x>> is treated as octal; all other strings are
treated as decimal. If <[base]> is between 2 and 36, it is used as the
conversion radix, as described above. If the subject string begins with
a minus sign, the value is negated. Finally, a pointer to the first
character past the converted subject string is stored in <[ptr]>, if
<[ptr]> is not <<NULL>>.

If the subject string is empty (or not in acceptable form), no conversion
is performed and the value of <[s]> is stored in <[ptr]> (if <[ptr]> is
not <<NULL>>).

The alternate function <<_strtoll_r>> is a reentrant version.  The
extra argument <[reent]> is a pointer to a reentrancy structure.

RETURNS
<<strtoll>> returns the converted value, if any. If no conversion was
made, 0 is returned.

<<strtoll>> returns <<LONG_LONG_MAX>> or <<LONG_LONG_MIN>> if the magnitude of
the converted value is too large, and sets <<errno>> to <<ERANGE>>.

PORTABILITY
<<strtoll>> is ANSI.

No supporting OS subroutines are required.
*/

/*-
 * Copyright (c) 1990 The Regents of the University of California.
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
#include <limits.h>
#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <reent.h>

#ifndef _REENT_ONLY

long long
_DEFUN (strtoll, (s, ptr, base),
	_CONST char *s _AND
	char **ptr _AND
	int base)
{
	return _strtoll_r (_REENT, s, ptr, base);
}

#endif

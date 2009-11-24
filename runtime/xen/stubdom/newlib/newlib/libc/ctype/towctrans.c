/* Copyright (c) 2002 Red Hat Incorporated.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

     Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

     Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

     The name of Red Hat Incorporated may not be used to endorse
     or promote products derived from this software without specific
     prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED.  IN NO EVENT SHALL RED HAT INCORPORATED BE LIABLE FOR ANY
   DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
   ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS   
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
FUNCTION
	<<towctrans>>---extensible wide-character translation

INDEX
	towctrans

ANSI_SYNOPSIS
	#include <wctype.h>
	wint_t towctrans(wint_t <[c]>, wctrans_t <[w]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	wint_t towctrans(<[c]>, <[w]>)
	wint_t <[c]>;
	wctrans_t <[w]>;


DESCRIPTION
<<towctrans>> is a function which converts wide characters based on
a specified translation type <[w]>.  If the translation type is
invalid or cannot be applied to the current character, no change
to the character is made.

RETURNS
<<towctrans>> returns the translated equivalent of <[c]> when it is a
valid for the given translation, otherwise, it returns the input character.
When the translation type is invalid, <<errno>> is set <<EINVAL>>.

PORTABILITY
<<towctrans>> is C99.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <string.h>
#include <reent.h>
#include <wctype.h>
#include <errno.h>
#include "local.h"

wint_t
_DEFUN (_towctrans_r, (r, c, w), 
	struct _reent *r _AND
	wint_t c _AND 
	wctrans_t w)
{
  if (w == WCT_TOLOWER)
    return towlower (c);
  else if (w == WCT_TOUPPER)
    return towupper (c);
  else
    {
      r->_errno = EINVAL;
      return c;
    }
}

#ifndef _REENT_ONLY
wint_t
_DEFUN (towctrans, (c, w),
	wint_t c _AND
        wctrans_t w)
{
  return _towctrans_r (_REENT, c, w);
}
#endif /* !_REENT_ONLY */

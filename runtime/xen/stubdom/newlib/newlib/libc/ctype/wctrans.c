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
	<<wctrans>>---get wide-character translation type

INDEX
	wctrans

ANSI_SYNOPSIS
	#include <wctype.h>
	wctrans_t wctrans(const char *<[c]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	wctrans_t wctrans(<[c]>)
	const char * <[c]>;


DESCRIPTION
<<wctrans>> is a function which takes a string <[c]> and gives back
the appropriate wctrans_t type value associated with the string,
if one exists.  The following values are guaranteed to be recognized:
"tolower" and "toupper".

RETURNS
<<wctrans>> returns 0 and sets <<errno>> to <<EINVAL>> if the
given name is invalid.  Otherwise, it returns a valid non-zero wctrans_t
value.

PORTABILITY
<<wctrans>> is C99.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <string.h>
#include <reent.h>
#include <wctype.h>
#include <errno.h>
#include "local.h"

wctrans_t
_DEFUN (_wctrans_r, (r, c), 
	struct _reent *r _AND
	const char *c)
{
  if (!strcmp (c, "tolower"))
    return WCT_TOLOWER;
  else if (!strcmp (c, "toupper"))
    return WCT_TOUPPER;
  else
    {
      r->_errno = EINVAL;
      return 0;
    }
}

#ifndef _REENT_ONLY
wctrans_t
_DEFUN (wctrans, (c),
	const char *c)
{
  return _wctrans_r (_REENT, c);
}
#endif /* !_REENT_ONLY */

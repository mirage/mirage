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
	<<towupper>>---translate wide characters to uppercase

INDEX
	towupper

ANSI_SYNOPSIS
	#include <wctype.h>
	wint_t towupper(wint_t <[c]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	wint_t towupper(<[c]>)
	wint_t <[c]>;


DESCRIPTION
<<towupper>> is a function which converts lowercase wide characters to
uppercase, leaving all other characters unchanged.

RETURNS
<<towupper>> returns the uppercase equivalent of <[c]> when it is a
lowercase wide character, otherwise, it returns the input character.

PORTABILITY
<<towupper>> is C99.

No supporting OS subroutines are required.
*/

#include <_ansi.h>
#include <newlib.h>
#include <string.h>
#include <reent.h>
#include <ctype.h>
#include <wctype.h>
#include "local.h"

wint_t
_DEFUN(towupper,(c), wint_t c)
{
  int unicode = 0;

  if (__lc_ctype[0] == 'C' && __lc_ctype[1] == '\0')
    {
      unicode = 0;
      /* fall-through */ 
    }
#ifdef _MB_CAPABLE
  else if (!strcmp (__lc_ctype, "C-JIS"))
    {
      c = __jp2uc (c, JP_JIS);
      unicode = 1;
    }
  else if (!strcmp (__lc_ctype, "C-SJIS"))
    {
      c = __jp2uc (c, JP_SJIS);
      unicode = 1;
    }
  else if (!strcmp (__lc_ctype, "C-EUCJP"))
    {
      c = __jp2uc (c, JP_EUCJP);
      unicode = 1;
    }
  else if (!strcmp (__lc_ctype, "C-UTF-8"))
    {
      unicode = 1;
    }

  if (unicode)
    {
      if (c < 0x100)
	{
	  if (c == 0x00b5)
	    return 0x039c;
	  
	  if ((c >= 0x00e0 && c <= 0x00fe) ||
	      (c >= 0x0061 && c <= 0x007a))
	    return (c - 0x20);
	  
	  if (c == 0xff)
	    return 0x0178;
	  
	  return c;
	}
      else if (c < 0x300)
	{
	  if ((c >= 0x0101 && c <= 0x012f) ||
	      (c >= 0x0133 && c <= 0x0137) ||
	      (c >= 0x014b && c <= 0x0177) ||
	      (c >= 0x01df && c <= 0x01ef) ||
	      (c >= 0x01f9 && c <= 0x021f) ||
	      (c >= 0x0223 && c <= 0x0233))
	    {
	      if (c & 0x01)
		return (c - 1);
	      return c;
	    }

	  if ((c >= 0x013a && c <= 0x0148) ||
	      (c >= 0x01ce && c <= 0x1dc))
	    {
	      if (!(c & 0x01))
		return (c - 1);
	      return c;
	    }
	  
	  if (c == 0x0131)
	    return 0x0049;
	  
	  if (c == 0x017a || c == 0x017c || c == 0x017e)
	    return (c - 1);
	  
	  if (c >= 0x017f && c <= 0x0292)
	    {
	      wint_t k;
	      switch (c)
		{
		case 0x017f:
		  k = 0x0053;
		  break;
		case 0x0183:
		  k = 0x0182;
		  break;
		case 0x0185:
		  k = 0x0184;
		  break;
		case 0x0188:
		  k = 0x0187;
		  break;
		case 0x018c:
		  k = 0x018b;
		  break;
		case 0x0192:
		  k = 0x0191;
		  break;
		case 0x0195:
		  k = 0x01f6;
		  break;
		case 0x0199:
		  k = 0x0198;
		  break;
		case 0x019e:
		  k = 0x0220;
		  break;
		case 0x01a1:
		case 0x01a3:
		case 0x01a5:
		case 0x01a8:
		case 0x01ad:
		case 0x01b0:
		case 0x01b4:
		case 0x01b6:
		case 0x01b9:
		case 0x01bd:
		case 0x01c5:
		case 0x01c8:
		case 0x01cb:
		case 0x01f2:
		case 0x01f5:
		  k = c - 1;
		  break;
		case 0x01bf:
		  k = 0x01f7;
		  break;
		case 0x01c6:
		case 0x01c9:
		case 0x01cc:
		  k = c - 2;
		  break;
		case 0x01dd:
		  k = 0x018e;
		  break;
		case 0x01f3:
		  k = 0x01f1;
		  break;
		case 0x0253:
		  k = 0x0181;
		  break;
		case 0x0254:
		  k = 0x0186;
		  break;
		case 0x0256:
		  k = 0x0189;
		  break;
		case 0x0257:
		  k = 0x018a;
		  break;
		case 0x0259:
		  k = 0x018f;
		  break;
		case 0x025b:
		  k = 0x0190;
		  break;
		case 0x0260:
		  k = 0x0193;
		  break;
		case 0x0263:
		  k = 0x0194;
		  break;
		case 0x0268:
		  k = 0x0197;
		  break;
		case 0x0269:
		  k = 0x0196;
		  break;
		case 0x026f:
		  k = 0x019c;
		  break;
		case 0x0272:
		  k = 0x019d;
		  break;
		case 0x0275:
		  k = 0x019f;
		  break;
		case 0x0280:
		  k = 0x01a6;
		  break;
		case 0x0283:
		  k = 0x01a9;
		  break;
		case 0x0288:
		  k = 0x01ae;
		  break;
		case 0x028a:
		  k = 0x01b1;
		  break;
		case 0x028b:
		  k = 0x01b2;
		  break;
		case 0x0292:
		  k = 0x01b7;
		  break;
		default:
		  k = 0;
		}
	      if (k != 0)
		return k;
	    }
	}
      else if (c < 0x0400)
	{
	  if (c == 0x03ac)
	    return 0x0386;
	  
	  if ((c & 0xfff0) == 0x03a0 && c >= 0x03ad)
	    return (c - 0x15);
	  
	  if (c >= 0x03b1 && c <= 0x03cb && c != 0x03c2)
	    return (c - 0x20);
	  
	  if (c == 0x03c2)
	    return 0x03a3;
	  
	  if (c >= 0x03cc && c <= 0x03f5)
	    {
	      wint_t k;
	      switch (c)
		{
		case 0x03cc:
		  k = 0x038c;
		  break;
		case 0x03cd:
		case 0x03ce:
		  k = c - 0x3f;
		  break;
		case 0x03d0:
		  k = 0x0392;
		  break;
		case 0x03d1:
		  k = 0x0398;
		  break;
		case 0x03d5:
		  k = 0x03a6;
		  break;
		case 0x03d6:
		  k = 0x03a0;
		  break;
		case 0x03d9:
		case 0x03db:
		case 0x03dd:
		case 0x03df:
		case 0x03e1:
		case 0x03e3:
		case 0x03e5:
		case 0x03e7:
		case 0x03e9:
		case 0x03eb:
		case 0x03ed:
		case 0x03ef:
		  k = c - 1;
		  break;
		case 0x03f0:
		  k = 0x039a;
		  break;
		case 0x03f1:
		  k = 0x03a1;
		  break;
		case 0x03f2:
		  k = 0x03a3;
		  break;
		case 0x03f5:
		  k = 0x0395;
		  break;
		default:
		  k = 0;
		}
	      if (k != 0)
		return k;
	    }
	}
      else if (c < 0x500)
	{
	  if (c >= 0x0450 && c <= 0x045f)
	    return (c - 0x50);
	  
	  if (c >= 0x0430 && c <= 0x044f)
	    return (c - 0x20);
	  
	  if ((c >= 0x0461 && c <= 0x0481) ||
	      (c >= 0x048b && c <= 0x04bf) ||
	      (c >= 0x04d1 && c <= 0x04f5))
	    {
	      if (c & 0x01)
		return (c - 1);
	      return c;
	    }
	  
	  if (c >= 0x04c2 && c <= 0x04ce)
	    {
	      if (!(c & 0x01))
		return (c - 1);
	      return c;
	    }
	  
	  if (c == 0x04f9)
	    return 0x04f8;
	}
      else if (c < 0x1f00)
	{
	  if ((c >= 0x0501 && c <= 0x050f) ||
	      (c >= 0x1e01 && c <= 0x1e95) ||
	      (c >= 0x1ea1 && c <= 0x1ef9))
	    {
	      if (c & 0x01)
		return (c - 1);
	      return c;
	    }
	  
	  if (c >= 0x0561 && c <= 0x0586)
	    return (c - 0x30);

	  if (c == 0x1e9b)
	    return 0x1e60;
	}
      else if (c < 0x2000)
	{
	  
	  if ((c >= 0x1f00 && c <= 0x1f07) ||
	      (c >= 0x1f10 && c <= 0x1f15) ||
	      (c >= 0x1f20 && c <= 0x1f27) ||
	      (c >= 0x1f30 && c <= 0x1f37) ||
	      (c >= 0x1f40 && c <= 0x1f45) ||
	      (c >= 0x1f60 && c <= 0x1f67) ||
	      (c >= 0x1f80 && c <= 0x1f87) ||
	      (c >= 0x1f90 && c <= 0x1f97) ||
	      (c >= 0x1fa0 && c <= 0x1fa7))
	    return (c + 0x08);
 
	  if (c >= 0x1f51 && c <= 0x1f57 && (c & 0x01))
	    return (c + 0x08);
	  
	  if (c >= 0x1f70 && c <= 0x1ff3)
	    {
	      wint_t k;
	      switch (c)
		{
		case 0x1fb0:
		  k = 0x1fb8;
		  break;
		case 0x1fb1:
		  k = 0x1fb9;
		  break;
		case 0x1f70:
		  k = 0x1fba;
		  break;
		case 0x1f71:
		  k = 0x1fbb;
		  break;
		case 0x1fb3:
		  k = 0x1fbc;
		  break;
		case 0x1fbe:
		  k = 0x0399;
		  break;
		case 0x1f72:
		  k = 0x1fc8;
		  break;
		case 0x1f73:
		  k = 0x1fc9;
		  break;
		case 0x1f74:
		  k = 0x1fca;
		  break;
		case 0x1f75:
		  k = 0x1fcb;
		  break;
		case 0x1fd0:
		  k = 0x1fd8;
		  break;
		case 0x1fd1:
		  k = 0x1fd9;
		  break;
		case 0x1f76:
		  k = 0x1fda;
		  break;
		case 0x1f77:
		  k = 0x1fdb;
		  break;
		case 0x1fe0:
		  k = 0x1fe8;
		  break;
		case 0x1fe1:
		  k = 0x1fe9;
		  break;
		case 0x1f7a:
		  k = 0x1fea;
		  break;
		case 0x1f7b:
		  k = 0x1feb;
		  break;
		case 0x1fe5:
		  k = 0x1fec;
		  break;
		case 0x1f78:
		  k = 0x1ff8;
		  break;
		case 0x1f79:
		  k = 0x1ff9;
		  break;
		case 0x1f7c:
		  k = 0x1ffa;
		  break;
		case 0x1f7d:
		  k = 0x1ffb;
		  break;
		case 0x1ff3:
		  k = 0x1ffc;
		  break;
		default:
		  k = 0;
		}
	      if (k != 0)
		return k;
	    }
	}
      else 
	{
	  if (c >= 0x2170 && c <= 0x217f)
	    return (c - 0x10);
	  
	  if (c >= 0x24d0 && c <= 0x24e9)
	    return (c - 0x1a);
	  
	  if (c >= 0xff41 && c <= 0xff5a)
	    return (c - 0x20);
	  
	  if (c >= 0x10428 && c <= 0x1044d)
	    return (c - 0x28);
	}
    }     
#endif /* _MB_CAPABLE */
  
  return (c < 0x00ff ? (wint_t)(toupper ((int)c)) : c);
}


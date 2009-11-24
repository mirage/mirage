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
	<<towlower>>---translate wide characters to lowercase

INDEX
	towlower

ANSI_SYNOPSIS
	#include <wctype.h>
	wint_t towlower(wint_t <[c]>);

TRAD_SYNOPSIS
	#include <wctype.h>
	wint_t towlower(<[c]>)
	wint_t <[c]>;


DESCRIPTION
<<towlower>> is a function which converts uppercase wide characters to
lowercase, leaving all other characters unchanged.

RETURNS
<<towlower>> returns the lowercase equivalent of <[c]> when it is a
uppercase wide character; otherwise, it returns the input character.

PORTABILITY
<<towlower>> is C99.

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
_DEFUN(towlower,(c), wint_t c)
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
	  if ((c >= 0x0041 && c <= 0x005a) ||
	      (c >= 0x00c0 && c <= 0x00de))
	    return (c + 0x20);

	  if (c == 0x00b5)
	    return 0x03bc;
	  
	  return c;
	}
      else if (c < 0x300)
	{
	  if ((c >= 0x0100 && c <= 0x012e) ||
	      (c >= 0x0132 && c <= 0x0136) ||
	      (c >= 0x014a && c <= 0x0176) ||
	      (c >= 0x01de && c <= 0x01ee) ||
	      (c >= 0x01f8 && c <= 0x021e) ||
	      (c >= 0x0222 && c <= 0x0232))
	    {
	      if (!(c & 0x01))
		return (c + 1);
	      return c;
	    }

	  if ((c >= 0x0139 && c <= 0x0147) ||
	      (c >= 0x01cd && c <= 0x91db))
	    {
	      if (c & 0x01)
		return (c + 1);
	      return c;
	    }
	  
	  if (c >= 0x178 && c <= 0x01f7)
	    {
	      wint_t k;
	      switch (c)
		{
		case 0x0178:
		  k = 0x00ff;
		  break;
		case 0x0179:
		case 0x017b:
		case 0x017d:
		case 0x0182:
		case 0x0184:
		case 0x0187:
		case 0x018b:
		case 0x0191:
		case 0x0198:
		case 0x01a0:
		case 0x01a2:
		case 0x01a4:
		case 0x01a7:
		case 0x01ac:
		case 0x01af:
		case 0x01b3:
		case 0x01b5:
		case 0x01b8:
		case 0x01bc:
		case 0x01c5:
		case 0x01c8:
		case 0x01cb:
		case 0x01cd:
		case 0x01cf:
		case 0x01d1:
		case 0x01d3:
		case 0x01d5:
		case 0x01d7:
		case 0x01d9:
		case 0x01db:
		case 0x01f2:
		case 0x01f4:
		  k = c + 1;
		  break;
		case 0x017f:
		  k = 0x0073;
		  break;
		case 0x0181:
		  k = 0x0253;
		  break;
		case 0x0186:
		  k = 0x0254;
		  break;
		case 0x0189:
		  k = 0x0256;
		  break;
		case 0x018a:
		  k = 0x0257;
		  break;
		case 0x018e:
		  k = 0x01dd;
		  break;
		case 0x018f:
		  k = 0x0259;
		  break;
		case 0x0190:
		  k = 0x025b;
		  break;
		case 0x0193:
		  k = 0x0260;
		  break;
		case 0x0194:
		  k = 0x0263;
		  break;
		case 0x0196:
		  k = 0x0269;
		  break;
		case 0x0197:
		  k = 0x0268;
		  break;
		case 0x019c:
		  k = 0x026f;
		  break;
		case 0x019d:
		  k = 0x0272;
		  break;
		case 0x019f:
		  k = 0x0275;
		  break;
		case 0x01a6:
		  k = 0x0280;
		  break;
		case 0x01a9:
		  k = 0x0283;
		  break;
		case 0x01ae:
		  k = 0x0288;
		  break;
		case 0x01b1:
		  k = 0x028a;
		  break;
		case 0x01b2:
		  k = 0x028b;
		  break;
		case 0x01b7:
		  k = 0x0292;
		  break;
		case 0x01c4:
		case 0x01c7:
		case 0x01ca:
		case 0x01f1:
		  k = c + 2;
		  break;
		case 0x01f6:
		  k = 0x0195;
		  break;
		case 0x01f7:
		  k = 0x01bf;
		  break;
		default:
		  k = 0;
		}
	      if (k != 0)
		return k;
	    }

	  if (c == 0x0220)
	    return 0x019e;
	}
      else if (c < 0x0400)
	{
	  if (c >= 0x0391 && c <= 0x03ab && c != 0x03a2)
	    return (c + 0x20);
	  if (c >= 0x03d8 && c <= 0x03ee && !(c & 0x01))
	    return (c + 1);
	  if (c >= 0x0386 && c <= 0x03f5)
	    {
	      wint_t k;
	      switch (c)
		{
		case 0x0386:
		  k = 0x03ac;
		  break;
		case 0x0388:
		  k = 0x03ad;
		  break;
		case 0x0389:
		  k = 0x03ae;
		  break;
		case 0x038a:
		  k = 0x03af;
		  break;
		case 0x038c:
		  k = 0x03cc;
		  break;
		case 0x038e:
		  k = 0x03cd;
		  break;
		case 0x038f:
		  k = 0x038f;
		  break;
		case 0x03c2:
		  k = 0x03c3;
		  break;
		case 0x03d0:
		  k = 0x03b2;
		  break;
		case 0x03d1:
		  k = 0x03b8;
		  break;
		case 0x03d5:
		  k = 0x03c6;
		  break;
		case 0x03d6:
		  k = 0x03c0;
		  break;
		case 0x03f0:
		  k = 0x03ba;
		  break;
		case 0x03f1:
		  k = 0x03c1;
		  break;
		case 0x03f2:
		  k = 0x03c3;
		  break;
		case 0x03f4:
		  k = 0x03b8;
		  break;
		case 0x03f5:
		  k = 0x03b5;
		  break;
		default:
		  k = 0;
		}
	      if (k != 0)
		return k;
	    }

	  if (c == 0x0345)
	    return 0x03b9;
	}
      else if (c < 0x500)
	{
	  if (c >= 0x0400 && c <= 0x040f)
	    return (c + 0x50);
	  
	  if (c >= 0x0410 && c <= 0x042f)
	    return (c + 0x20);
	  
	  if ((c >= 0x0460 && c <= 0x0480) ||
	      (c >= 0x048a && c <= 0x04be) ||
	      (c >= 0x04d0 && c <= 0x04f4) ||
	      (c == 0x04f8))
	    {
	      if (!(c & 0x01))
		return (c + 1);
	      return c;
	    }
	  
	  if (c >= 0x04c1 && c <= 0x04cd)
	    {
	      if (c & 0x01)
		return (c + 1);
	      return c;
	    }
	}
      else if (c < 0x1f00)
	{
	  if ((c >= 0x0500 && c <= 0x050e) ||
	      (c >= 0x1e00 && c <= 0x1e94) ||
	      (c >= 0x1ea0 && c <= 0x1ef8))
	    {
	      if (!(c & 0x01))
		return (c + 1);
	      return c;
	    }
	  
	  if (c >= 0x0531 && c <= 0x0556)
	    return (c + 0x30);

	  if (c == 0x1e9b)
	    return 0x1e61;
	}
      else if (c < 0x2000)
	{
	  if ((c >= 0x1f08 && c <= 0x1f0f) ||
	      (c >= 0x1f18 && c <= 0x1f1d) ||
	      (c >= 0x1f28 && c <= 0x1f2f) ||
	      (c >= 0x1f38 && c <= 0x1f3f) ||
	      (c >= 0x1f48 && c <= 0x1f4d) ||
	      (c >= 0x1f68 && c <= 0x1f6f) ||
	      (c >= 0x1f88 && c <= 0x1f8f) ||
	      (c >= 0x1f98 && c <= 0x1f9f) ||
	      (c >= 0x1fa8 && c <= 0x1faf))
	    return (c - 0x08);

	  if (c >= 0x1f59 && c <= 0x1f5f)
	    {
	      if (c & 0x01)
		return (c - 0x08);
	      return c;
	    }
	
	  if (c >= 0x1fb8 && c <= 0x1ffc)
	    {
	      wint_t k;
	      switch (c)
		{
		case 0x1fb8:
		case 0x1fb9:
		case 0x1fd8:
		case 0x1fd9:
		case 0x1fe8:
		case 0x1fe9:
		  k = c - 0x08;
		  break;
		case 0x1fba:
		case 0x1fbb:
		  k = c - 0x4a;
		  break;
		case 0x1fbc:
		  k = 0x1fb3;
		  break;
		case 0x1fbe:
		  k = 0x03b9;
		  break;
		case 0x1fc8:
		case 0x1fc9:
		case 0x1fca:
		case 0x1fcb:
		  k = c - 0x56;
		  break;
		case 0x1fcc:
		  k = 0x1fc3;
		  break;
		case 0x1fda:
		case 0x1fdb:
		  k = c - 0x64;
		  break;
		case 0x1fea:
		case 0x1feb:
		  k = c - 0x70;
		  break;
		case 0x1fec:
		  k = 0x1fe5;
		  break;
		case 0x1ffa:
		case 0x1ffb:
		  k = c - 0x7e;
		  break;
		case 0x1ffc:
		  k = 0x1ff3;
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
	  if (c >= 0x2160 && c <= 0x216f)
	    return (c + 0x10);
	  
	  if (c >= 0x24b6 && c <= 0x24cf)
	    return (c + 0x1a);
	  
	  if (c >= 0xff21 && c <= 0xff3a)
	    return (c + 0x20);
	  
	  if (c >= 0x10400 && c <= 0x10425)
	    return (c + 0x28);

	  if (c == 0x2126)
	    return 0x03c9;
	  if (c == 0x212a)
	    return 0x006b;
	  if (c == 0x212b)
	    return 0x00e5;
	}
    }     
#endif /* _MB_CAPABLE */
  
  return (c < 0x00ff ? (wint_t)(tolower ((int)c)) : c);
}


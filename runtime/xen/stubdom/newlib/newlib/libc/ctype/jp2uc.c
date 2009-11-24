/* Routine to translate from Japanese characters to Unicode */

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

#include <newlib.h>

#ifdef _MB_CAPABLE

#include <_ansi.h>
#include <wctype.h>
#include "local.h"
#include "jp2uc.h"

wint_t
_DEFUN (__jp2uc, (c, type), wint_t c _AND int type)
{
  int index, adj;
  unsigned char byte1, byte2;
  wint_t ret;

  /* we actually use tables of EUCJP to Unicode.  For JIS, we simply
     note that EUCJP is essentially JIS with the top bits on in each
     byte and translate to EUCJP.  For SJIS, we do a translation to EUCJP before
     accessing the tables. */
  switch (type)
    {
    case JP_JIS:
      byte1 = (c >> 8) + 0x80;
      byte2 = (c & 0xff) + 0x80;
      break;
    case JP_EUCJP:
      byte1 = (c >> 8);
      byte2 = (c & 0xff);
      break;
    case JP_SJIS:
      byte1 = c >> 8;
      byte2 = c & 0xff;
      if (byte2 <= 0x9e)
        {
          adj = 0xa1 - 0x22;
          byte2 = (byte2 - 31) + 0xa1;
        }
      else
        {
          adj = 0xa1 - 0x21;
          byte2 = (byte2 - 126) + 0xa1;
        }
      if (byte1 <= 0x9f)
        byte1 = ((byte1 - 112) << 1) + adj;
      else
        byte1 = ((byte1 - 176) << 1) + adj;
      break;
    default:
      return WEOF;
    }

  /* find conversion in jp2uc arrays */

  /* handle larger ranges first */
  if (byte1 >= 0xb0 && byte1 <= 0xcf && c <= 0xcfd3)
    {
      index = (byte1 - 0xb0) * 0xfe + (byte2 - 0xa1);
      return b02cf[index];
    }
  else if (byte1 >= 0xd0 && byte1 <= 0xf4 && c <= 0xf4a6)
    {
      index = (byte1 - 0xd0) * 0xfe + (byte2 - 0xa1);
      return d02f4[index];
    }

  /* handle smaller ranges here */    
  switch (byte1)
    {
    case 0xA1:
      return (wint_t)a1[byte2 - 0xa1];
    case 0xA2:
      ret = a2[byte2 - 0xa1];
      if (ret != 0)
	return (wint_t)ret;
      break;
    case 0xA3:
      if (a3[byte2 - 0xa1])
	return (wint_t)(0xff00 + (byte2 - 0xa0));
      break;
    case 0xA4:
      if (byte2 <= 0xf3)
	return (wint_t)(0x3000 + (byte2 - 0x60));
      break;
    case 0xA5:
      if (byte2 <= 0xf6)
	return (wint_t)(0x3000 + byte2);
      break;
    case 0xA6:
      ret = 0;
      if (byte2 <= 0xd8)
	ret = (wint_t)a6[byte2 - 0xa1];
      if (ret != 0)
	return ret;
      break;
    case 0xA7:
      ret = 0;
      if (byte2 <= 0xf1)
	ret = (wint_t)a7[byte2 - 0xa1];
      if (ret != 0)
	return ret;
      break;
    case 0xA8:
      if (byte2 <= 0xc0)
	return (wint_t)a8[byte2 - 0xa1];
      break;
    default:
      return WEOF;
    }

  return WEOF; 
}

#endif /* _MB_CAPABLE */

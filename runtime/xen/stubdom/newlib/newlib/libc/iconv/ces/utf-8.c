/*
 * Copyright (c) 2003-2004, Artem B. Bityuckiy
 * Copyright (c) 1999,2000, Konstantin Chuguev. All rights reserved.
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
#include "cesbi.h"

#if defined (ICONV_TO_UCS_CES_UTF_8) \
 || defined (ICONV_FROM_UCS_CES_UTF_8)

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include "../lib/local.h"
#include "../lib/ucsconv.h"

#define UTF8_MB_CUR_MAX 6

/*
 * UTF-8 CES converter doesn't interpret BOM. Reject overlong sequences, 
 * U'FFFF, U'FFFE codes, UTF-16 surrogate codes and all codes > 0x7FFFFFFF.
 */

#if defined (ICONV_FROM_UCS_CES_UTF_8)
static size_t
_DEFUN(convert_from_ucs, (data, in, outbuf, outbytesleft),
                         _VOID_PTR data         _AND
                         register ucs4_t in     _AND
                         unsigned char **outbuf _AND
                         size_t *outbytesleft)
{
  register unsigned char *cp;
  register size_t bytes;

  if ((in  >= 0x0000D800 && in <= 0x0000DFFF)
      || in > 0x7FFFFFFF || in == 0x0000FFFF || in == 0x0000FFFE)
    return (size_t)ICONV_CES_INVALID_CHARACTER;

  if (in < 0x80)
    bytes = 1;
  else if (in < 0x800)
    bytes = 2;
  else if (in < 0x10000)
    bytes = 3;
  else if (in < 0x200000)
    bytes = 4;
  else if (in < 0x4000000)
    bytes = 5;
  else
    bytes = 6;

  if (*outbytesleft < bytes)
    return (size_t)ICONV_CES_NOSPACE;

  cp = *outbuf;
  
  switch (bytes)
    {
      case 1:
        *cp = (unsigned char)in;
        break;

      case 2:
        *cp++ = (unsigned char)((in >> 6) | 0x000000C0);
        *cp++ = (unsigned char)((in & 0x0000003F) | 0x00000080);
        break;

      case 3:
        *cp++ = (unsigned char)((in >> 12) | 0x000000E0);
        *cp++ = (unsigned char)(((in >> 6) & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)((in        & 0x0000003F) | 0x00000080);
        break;

      case 4:
        *cp++ = (unsigned char)((in >> 18)  | 0x000000F0);
        *cp++ = (unsigned char)(((in >> 12) & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)(((in >> 6)  & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)((in         & 0x0000003F) | 0x00000080);
        break;

      case 5:
        *cp++ = (unsigned char)((in >> 24)  | 0x000000F8);
        *cp++ = (unsigned char)(((in >> 18) & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)(((in >> 12) & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)(((in >> 6)  & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)((in         & 0x0000003F) | 0x00000080);
        break;

      case 6:
        *cp++ = (unsigned char)((in >> 30)  | 0x000000FC);
        *cp++ = (unsigned char)(((in >> 24) & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)(((in >> 18) & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)(((in >> 12) & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)(((in >> 6)  & 0x0000003F) | 0x00000080);
        *cp++ = (unsigned char)((in         & 0x0000003F) | 0x00000080);
        break;
    }

  *outbytesleft -= bytes;
  *outbuf += bytes;
  
  return bytes;
}
#endif /* ICONV_FROM_UCS_CES_UTF_8 */

#if defined (ICONV_TO_UCS_CES_UTF_8)
static ucs4_t
_DEFUN(convert_to_ucs, (data, inbuf, inbytesleft),
                       _VOID_PTR data               _AND
                       _CONST unsigned char **inbuf _AND
                       size_t *inbytesleft)
{
  register _CONST unsigned char *in = *inbuf;
  register size_t bytes;
  ucs4_t res;

  if (in[0] >= 0xC0)
    {
      if (in[0] < 0xE0)
        {
          if (*inbytesleft < (bytes = 2))
            return (ucs4_t)ICONV_CES_BAD_SEQUENCE;

          if (   ((in[0] & ~0x1F) == 0xC0)
              && ((in[1] & 0xC0)  == 0x80))
            res = ((ucs4_t)(in[0] & 0x1F) << 6)
                | ((ucs4_t)(in[1] & 0x3F));
          else
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;

          if (res < 0x00000080) /* Overlong sequence */
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
        }
        
      else if (in[0] < 0xF0)
        {
          if (*inbytesleft < (bytes = 3))
            return (ucs4_t)ICONV_CES_BAD_SEQUENCE;

          if (   ((in[0] & ~0x0F) == 0xE0)
              && ((in[1] & 0xC0)  == 0x80)
              && ((in[2] & 0xC0)  == 0x80))
            res = ((ucs4_t)(in[0] & 0x0F) << 12)
                | ((ucs4_t)(in[1] & 0x3F) << 6)
                | ((ucs4_t)(in[2] & 0x3F));
          else
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;

          if (res < 0x00000800) /* Overlong sequence */
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
        }
      
      else if (in[0] < 0xF8)
        {
          if (*inbytesleft < (bytes = 4))
            return (ucs4_t)ICONV_CES_BAD_SEQUENCE;
            
          if (   ((in[0] & ~0x07) == 0xF0)
              && ((in[1] & 0xC0)  == 0x80)
              && ((in[2] & 0xC0)  == 0x80)
              && ((in[3] & 0xC0)  == 0x80))
            res = ((ucs4_t)(in[0] & 0x07) << 18)
                | ((ucs4_t)(in[1] & 0x3F) << 12)
                | ((ucs4_t)(in[2] & 0x3F) << 6)
                | ((ucs4_t)(in[3] & 0x3F));
          else
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
            
          if (res < 0x00010000) /* Overlong sequence */
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
        }
      
      else if (in[0] < 0xFC)
        {
          if (*inbytesleft < (bytes = 5))
            return (ucs4_t)ICONV_CES_BAD_SEQUENCE;
            
          if (   ((in[0] & ~0x03) == 0xF8)
              && ((in[1] & 0xC0)  == 0x80)
              && ((in[2] & 0xC0)  == 0x80)
              && ((in[3] & 0xC0)  == 0x80)
              && ((in[4] & 0xC0)  == 0x80))
            res = ((ucs4_t)(in[0] & 0x03) << 24)
                | ((ucs4_t)(in[1] & 0x3F) << 18)
                | ((ucs4_t)(in[2] & 0x3F) << 12)
                | ((ucs4_t)(in[3] & 0x3F) << 6)
                | ((ucs4_t)(in[4] & 0x3F));
          else
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
            
          if (res < 0x00200000) /* Overlong sequence */
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
        }

      else if (in[0] <= 0xFD)
        {
          if (*inbytesleft < (bytes = 6))
            return (ucs4_t)ICONV_CES_BAD_SEQUENCE;
            
          if (   ((in[0] & ~0x01) == 0xFC)
              && ((in[1] & 0xC0)  == 0x80)
              && ((in[2] & 0xC0)  == 0x80)
              && ((in[3] & 0xC0)  == 0x80)
              && ((in[4] & 0xC0)  == 0x80)
              && ((in[5] & 0xC0)  == 0x80))
              res = ((ucs4_t)(in[0] & 0x1)  << 30)
                  | ((ucs4_t)(in[1] & 0x3F) << 24)
                  | ((ucs4_t)(in[2] & 0x3F) << 18)
                  | ((ucs4_t)(in[3] & 0x3F) << 12)
                  | ((ucs4_t)(in[4] & 0x3F) << 6)
                  | ((ucs4_t)(in[5] & 0x3F));
          else
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
            
          if (res < 0x04000000) /* Overlong sequence */
            return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
        }
        
      else
        return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
    }
  else if (in[0] & 0x80)
    return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
  else
    {
      res = (ucs4_t)in[0];
      bytes = 1;
    }

  if (  (res  >= 0x0000D800 && res <= 0x0000DFFF)
      || res > 0x7FFFFFFF || res == 0x0000FFFF || res == 0x0000FFFE)
    return (ucs4_t)ICONV_CES_INVALID_CHARACTER;

  *inbytesleft -= bytes;
  *inbuf += bytes;

  return res;
}
#endif /* ICONV_TO_UCS_CES_UTF_8 */

static int
_DEFUN(get_mb_cur_max, (data),
                       _VOID_PTR data)
{
  return UTF8_MB_CUR_MAX;
}

#if defined (ICONV_TO_UCS_CES_UTF_8)
_CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_utf_8 = 
{
  NULL,
  NULL,
  get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  convert_to_ucs
};
#endif

#if defined (ICONV_FROM_UCS_CES_UTF_8)
_CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_utf_8 =
{
  NULL,
  NULL,
  get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  convert_from_ucs
};
#endif

#endif /* ICONV_TO_UCS_CES_UTF_8 || ICONV_FROM_UCS_CES_UTF_8 */


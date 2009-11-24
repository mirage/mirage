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

#if defined (ICONV_TO_UCS_CES_UTF_16) \
 || defined (ICONV_FROM_UCS_CES_UTF_16)

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include "../lib/local.h"
#include "../lib/ucsconv.h"
#include "../lib/endian.h"

/*
 * On input UTF-16 converter interpret BOM and uses Big Endian byte order if BOM
 * is absent. UTF-16 converter outputs in System Endian and adds correspondent
 * BOM as first code. UTF-16LE and UTF-16BE converters ignore BOM on input and
 * don't output BOM.
 */

#define UTF16_UNDEFINED     0x00
#define UTF16_BIG_ENDIAN    0x01
#define UTF16_LITTLE_ENDIAN 0x02
#define UTF16_SYSTEM_ENDIAN 0x04
#define UTF16_BOM_WRITTEN   0x08

#define UTF16_BOM 0xFEFF

#define UTF_16   "utf_16"
#define UTF_16BE "utf_16be"
#define UTF_16LE "utf_16le"

static size_t
_DEFUN(utf_16_close, (rptr, data),
                     struct _reent *rptr _AND
                     _VOID_PTR data)
{
  _free_r(rptr, data);
  return 0;
}

#if defined (ICONV_FROM_UCS_CES_UTF_16)
static _VOID_PTR
_DEFUN(utf_16_init_from_ucs, (rptr, encoding),
                             struct _reent *rptr _AND
                             _CONST char *encoding)
{
  int *data;
  
  if ((data = (int *)_malloc_r (rptr, sizeof (int))) == NULL)
    return (_VOID_PTR)NULL;
  
  if (strcmp (encoding, UTF_16LE) == 0)
    *data = UTF16_LITTLE_ENDIAN;
  else if (strcmp (encoding, UTF_16BE) == 0)
    *data = UTF16_BIG_ENDIAN;
  else
    *data = UTF16_SYSTEM_ENDIAN;
     
  return (_VOID_PTR)data;
}

static size_t
_DEFUN(utf_16_convert_from_ucs, (data, in, outbuf, outbytesleft),
                                _VOID_PTR data         _AND
                                register ucs4_t in     _AND
                                unsigned char **outbuf _AND
                                size_t *outbytesleft)
{
  register ucs2_t *cp;
  register size_t bytes;
  register int *state;
  
  if (in > 0x0010FFFF || (in >= 0x0000D800 && in <= 0x0000DFFF)
      || in == 0x0000FFFF || in == 0x0000FFFE)
    return (size_t)ICONV_CES_INVALID_CHARACTER; 

  state = (int *)data;
  bytes = (*state == UTF16_SYSTEM_ENDIAN) ? sizeof (ucs2_t) * 2 
                                          : sizeof (ucs2_t);

  if (in > 0x0000FFFF)
    bytes += sizeof (ucs2_t);

  if (*outbytesleft < bytes)
    return (size_t)ICONV_CES_NOSPACE;

  cp = (ucs2_t *)*outbuf;

  if (*state == UTF16_SYSTEM_ENDIAN)
    {
      *cp++ = UTF16_BOM;
      *state |= UTF16_BOM_WRITTEN;
    }

  if (in < 0x00010000)
    {
      switch (*state)
        {
          case UTF16_LITTLE_ENDIAN:
            *cp = ICONV_HTOLES ((ucs2_t)in);
            break;
          case UTF16_BIG_ENDIAN:
            *cp = ICONV_HTOBES ((ucs2_t)in);
            break;
          case (UTF16_SYSTEM_ENDIAN | UTF16_BOM_WRITTEN):
            *cp = (ucs2_t)in;
            break;
        }
    }
  else
    {
      ucs2_t w1, w2;
      
      /* Process surrogate pair */
      in -= 0x00010000;
      w1 = ((ucs2_t)((in >> 10)) & 0x03FF) | 0xD800;
      w2 = (ucs2_t)(in & 0x000003FF) | 0xDC00;

      switch (*state)
        {
          case UTF16_LITTLE_ENDIAN:
            *cp++ = ICONV_HTOLES (w1);
            *cp = ICONV_HTOLES (w2);
            break;
          case UTF16_BIG_ENDIAN:
            *cp++ = ICONV_HTOBES (w1);
            *cp = ICONV_HTOBES (w2);
            break;
          case (UTF16_SYSTEM_ENDIAN | UTF16_BOM_WRITTEN):
            *cp++ = w1;
            *cp = w2;
            break;
        }
    }
  
  *outbuf += bytes;
  *outbytesleft -= bytes;

  return bytes;
}
#endif /* ICONV_FROM_UCS_CES_UTF_16 */

#if defined (ICONV_TO_UCS_CES_UTF_16)
static _VOID_PTR
_DEFUN(utf_16_init_to_ucs, (rptr, encoding),
                           struct _reent *rptr _AND
                           _CONST char *encoding)
{
  int *data;
  
  if ((data = (int *)_malloc_r (rptr, sizeof (int))) == NULL)
    return (_VOID_PTR)NULL;
  
  if (strcmp (encoding, UTF_16BE) == 0)
    *data = UTF16_BIG_ENDIAN;
  else if (strcmp (encoding, UTF_16LE) == 0)
    *data = UTF16_LITTLE_ENDIAN;
  else
    *data = UTF16_UNDEFINED;
     
  return (_VOID_PTR)data;
}

static ucs4_t
_DEFUN(utf_16_convert_to_ucs, (data, inbuf, inbytesleft),
                              _VOID_PTR data               _AND
                              _CONST unsigned char **inbuf _AND
                              size_t *inbytesleft)
{
  register ucs2_t w1;
  register ucs2_t w2;
  register ucs2_t *cp;
  int *state;
  ucs4_t res;
  int bytes = sizeof (ucs2_t);

  if (*inbytesleft < bytes)
    return (ucs4_t)ICONV_CES_BAD_SEQUENCE;
  
  state = (int *)data;
  cp = ((ucs2_t *)*inbuf);

  if (*state == UTF16_UNDEFINED)
    {
      if (*cp == ICONV_HTOLES(UTF16_BOM))
        *state = UTF16_LITTLE_ENDIAN;
      else
        *state = UTF16_BIG_ENDIAN;

     if (   *cp == ICONV_HTOBES (UTF16_BOM)
         || *cp == ICONV_HTOLES (UTF16_BOM))
       {
         if (*inbytesleft < (bytes += sizeof (ucs2_t)))
           return (ucs4_t)ICONV_CES_BAD_SEQUENCE;
         cp += 1;
       }
    }
    
  if (*state == UTF16_LITTLE_ENDIAN)      
    w1 = ICONV_LETOHS (*cp);
  else
    w1 = ICONV_BETOHS (*cp);

  if (w1  < 0xD800 || w1 > 0xDFFF)
    {
      if (w1 == 0xFFFF || w1 == 0xFFFE)
        return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
      res = (ucs4_t)w1;
    }
  else
    {
      /* Process surrogate pair */
      if (*inbytesleft < (bytes += 2))
        return (ucs4_t)ICONV_CES_BAD_SEQUENCE;
    
      if (w1 > 0xDBFF)
        /* Broken surrogate character */
        return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
        
      cp += 1;

      if (*state == UTF16_LITTLE_ENDIAN)      
        w2 = ICONV_LETOHS (*cp);
      else
        w2 = ICONV_BETOHS (*cp);
  
      if (w2 < 0xDC00 || w2 > 0xDFFF)
        /* Broken surrogate character */
        return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
    
      res = (ucs4_t)(w2 & 0x03FF) | ((ucs4_t)(w1 & 0x03FF) << 10);
      res += 0x00010000;
    }

  *inbuf += bytes;
  *inbytesleft -= bytes;
  
  return res;
}
#endif /* ICONV_TO_UCS_CES_UTF_16 */

static int
_DEFUN(utf_16_get_mb_cur_max, (data),
                              _VOID_PTR data)
{
  return 6;
}

#if defined (ICONV_TO_UCS_CES_UTF_16)
_CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_utf_16 = 
{
  utf_16_init_to_ucs,
  utf_16_close,
  utf_16_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  utf_16_convert_to_ucs
};
#endif

#if defined (ICONV_FROM_UCS_CES_UTF_16)
_CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_utf_16 =
{
  utf_16_init_from_ucs,
  utf_16_close,
  utf_16_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  utf_16_convert_from_ucs
};
#endif

#endif /* ICONV_TO_UCS_CES_UTF_16 || ICONV_FROM_UCS_CES_UTF_16 */


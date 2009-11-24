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

#if defined (ICONV_TO_UCS_CES_UCS_2) \
 || defined (ICONV_FROM_UCS_CES_UCS_2)

#include <_ansi.h>
#include <reent.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include "../lib/local.h"
#include "../lib/ucsconv.h"
#include "../lib/endian.h"

/*
 * BOM isn't supported. UCS-2 is Big Endian. Bad codes are rejected.
 * Bad codes: 0xFFFF, 0xFFFE, 0xD800-0xDFFF.
 */

#define UCS_2_BIG_ENDIAN     0
#define UCS_2_LITTLE_ENDIAN  1

#define UCS_2   "ucs_2"
#define UCS_2BE "ucs_2be"
#define UCS_2LE "ucs_2le"

static _VOID_PTR
_DEFUN(ucs_2_init, (rptr, encoding),
                   struct _reent *rptr _AND
                   _CONST char *encoding)
{
  int *data;
  
  if ((data = (int *) _malloc_r(rptr, sizeof (int))) == NULL)
    return (_VOID_PTR)NULL;
  
  if (strcmp (encoding, UCS_2LE) == 0)
    *data = UCS_2_LITTLE_ENDIAN;
  else
    *data = UCS_2_BIG_ENDIAN;
     
  return (_VOID_PTR)data;
}

static size_t
_DEFUN(ucs_2_close, (rptr, data),
                    struct _reent *rptr _AND
                    _VOID_PTR data)
{
  _free_r (rptr, data);
  return 0;
}

#if defined (ICONV_FROM_UCS_CES_UCS_2)
static size_t
_DEFUN(ucs_2_convert_from_ucs, (data, in, outbuf, outbytesleft),
                               _VOID_PTR data         _AND
                               ucs4_t in              _AND
                               unsigned char **outbuf _AND
                               size_t *outbytesleft)
{
  if ((in  >= 0x0000D800 && in <= 0x0000DFFF) /* Surrogate character */
      || in >= 0x0000FFFE)
    return (size_t)ICONV_CES_INVALID_CHARACTER;

  if (*outbytesleft < sizeof (ucs2_t))
    return (size_t)ICONV_CES_NOSPACE;

  if (*((int *)data) == UCS_2_BIG_ENDIAN)
    *((ucs2_t *)(*outbuf)) = ICONV_HTOBES ((ucs2_t)in);
  else
    *((ucs2_t *)(*outbuf)) = ICONV_HTOLES ((ucs2_t)in);
    
  *outbuf += sizeof (ucs2_t);
  *outbytesleft -= sizeof (ucs2_t);

  return sizeof (ucs2_t);
}
#endif /* ICONV_FROM_UCS_CES_UCS_2 */

#if defined (ICONV_TO_UCS_CES_UCS_2)
static ucs4_t
_DEFUN(ucs_2_convert_to_ucs, (data, inbuf, inbytesleft),
                             _VOID_PTR data               _AND
                             _CONST unsigned char **inbuf _AND
                             size_t *inbytesleft)
{
  ucs4_t res;
  
  if (*inbytesleft < sizeof (ucs2_t))
    return (ucs4_t)ICONV_CES_BAD_SEQUENCE;

  if (*((int *)data) == UCS_2_BIG_ENDIAN)
    res = (ucs4_t)ICONV_BETOHS (*((ucs2_t *)(*inbuf)));
  else
    res = (ucs4_t)ICONV_LETOHS (*((ucs2_t *)(*inbuf)));

  if ((res  >= 0x0000D800 && res <= 0x0000DFFF) /* Surrogate character */
      || res >= 0x0000FFFE)
    return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
    
  *inbytesleft -= sizeof (ucs2_t);
  *inbuf += sizeof (ucs2_t);

  return res;
}
#endif /* ICONV_TO_UCS_CES_UCS_2 */

static int
_DEFUN(ucs_2_get_mb_cur_max, (data),
                             _VOID_PTR data)
{
  return 2;
}

#if defined (ICONV_TO_UCS_CES_UCS_2)
_CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_ucs_2 = 
{
  ucs_2_init,
  ucs_2_close,
  ucs_2_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  ucs_2_convert_to_ucs
};
#endif

#if defined (ICONV_FROM_UCS_CES_UCS_2)
_CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_ucs_2 =
{
  ucs_2_init,
  ucs_2_close,
  ucs_2_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  ucs_2_convert_from_ucs
};
#endif

#endif /* ICONV_TO_UCS_CES_UCS_2 || ICONV_FROM_UCS_CES_UCS_2 */


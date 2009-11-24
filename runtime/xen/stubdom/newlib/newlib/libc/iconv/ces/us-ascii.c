/*
 * Copyright (c) 2003-2004, Artem B. Bityuckiy
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

#if defined (ICONV_TO_UCS_CES_US_ASCII) \
 || defined (ICONV_FROM_UCS_CES_US_ASCII)

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include "../lib/local.h"
#include "../lib/ucsconv.h"

/*
 * For optimization purposes us_ascii is implemented as separate CES converter.
 * Another possible way is to add us_ascii CCS and use table-based CES converter.
 */

#if defined (ICONV_FROM_UCS_CES_US_ASCII)
static size_t
_DEFUN(us_ascii_convert_from_ucs, (data, in, outbuf, outbytesleft),
                                  _VOID_PTR data         _AND
                                  ucs4_t in              _AND
                                  unsigned char **outbuf _AND
                                  size_t *outbytesleft)
{
  if (in  > 0x7F)
    return (size_t)ICONV_CES_INVALID_CHARACTER;

  *((char *)(*outbuf)) = (char)in;
    
  *outbuf += 1;
  *outbytesleft -= 1;

  return 1;
}
#endif /* ICONV_FROM_UCS_CES_US_ASCII */

#if defined (ICONV_TO_UCS_CES_US_ASCII)
static ucs4_t
_DEFUN(us_ascii_convert_to_ucs, (data, inbuf, inbytesleft),
                                _VOID_PTR data               _AND
                                _CONST unsigned char **inbuf _AND
                                size_t *inbytesleft)
{
  ucs4_t res;

  if (*inbytesleft < 1)
    return (ucs4_t)ICONV_CES_BAD_SEQUENCE;

  res = (ucs4_t)**inbuf;

  if (res  > 0x7F)
    return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
    
  *inbytesleft -= 1;
  *inbuf += 1;

  return res;
}
#endif /* ICONV_TO_UCS_CES_US_ASCII */

static int
_DEFUN(us_ascii_get_mb_cur_max, (data),
                                _VOID_PTR data)
{
  return 2;
}

#if defined (ICONV_TO_UCS_CES_US_ASCII)
_CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_us_ascii = 
{
  NULL,
  NULL,
  us_ascii_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  us_ascii_convert_to_ucs
};
#endif

#if defined (ICONV_FROM_UCS_CES_US_ASCII)
_CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_us_ascii =
{
  NULL,
  NULL,
  us_ascii_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  us_ascii_convert_from_ucs
};
#endif

#endif /* ICONV_TO_UCS_CES_US_ASCII || ICONV_FROM_UCS_CES_US_ASCII */


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

#if defined (ICONV_TO_UCS_CES_UCS_4_INTERNAL) \
 || defined (ICONV_FROM_UCS_CES_UCS_4_INTERNAL)

#include <_ansi.h>
#include <reent.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include "../lib/local.h"
#include "../lib/ucsconv.h"
#include "../lib/endian.h"

/*
 * Internal 4-byte representation of UCS-2 codes without restrictions and
 * without BOM support.
 */

#if defined (ICONV_FROM_UCS_CES_UCS_4_INTERNAL)
static size_t
_DEFUN(ucs_4_internal_convert_from_ucs, (data, in, outbuf, outbytesleft),
                                        _VOID_PTR data         _AND
                                        register ucs4_t in     _AND
                                        unsigned char **outbuf _AND
                                        size_t *outbytesleft)
{
  if (in > 0x7FFFFFFF)
    return (size_t)ICONV_CES_INVALID_CHARACTER;
    
  if (*outbytesleft < sizeof (ucs4_t))
    return (size_t)ICONV_CES_NOSPACE;

  *((ucs4_t *)(*outbuf)) = in;
  *outbytesleft -= sizeof (ucs4_t);
  *outbuf += sizeof (ucs4_t);

  return sizeof (ucs4_t);
}
#endif /* ICONV_FROM_UCS_CES_UCS_4_INTERNAL */

#if defined (ICONV_TO_UCS_CES_UCS_4_INTERNAL)
static ucs4_t
_DEFUN(ucs_4_internal_convert_to_ucs, (data, inbuf, inbytesleft),
                                      _VOID_PTR data               _AND
                                      _CONST unsigned char **inbuf _AND
                                      size_t *inbytesleft)
{
  register ucs4_t res;

  if (*inbytesleft < sizeof (ucs4_t))
    return (ucs4_t)ICONV_CES_BAD_SEQUENCE;

  res = *((ucs4_t *)(*inbuf));

  if (res > 0x7FFFFFFF)
    return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
    
  *inbytesleft -= sizeof (ucs4_t);
  *inbuf += sizeof (ucs4_t);
  
  return res;
}
#endif /* ICONV_TO_UCS_CES_UCS_4_INTERNAL */

static int
_DEFUN(ucs_4_internal_get_mb_cur_max, (data),
                                      _VOID_PTR data)
{
  return 2;
}

#if defined (ICONV_TO_UCS_CES_UCS_4_INTERNAL)
_CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_ucs_4_internal = 
{
  NULL,
  NULL,
  ucs_4_internal_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  ucs_4_internal_convert_to_ucs
};
#endif

#if defined (ICONV_FROM_UCS_CES_UCS_4_INTERNAL)
_CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_ucs_4_internal =
{
  NULL,
  NULL,
  ucs_4_internal_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  ucs_4_internal_convert_from_ucs
};
#endif

#endif /* ICONV_TO_UCS_CES_UCS_4_INTERNAL || ICONV_FROM_UCS_CES_UCS_4_INTERNAL */


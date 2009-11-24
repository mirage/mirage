/*
 * Copyright (c) 2003-2004, Artem B. Bityuckiy
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

/*
 * This CES converter is just an simple extension of table CES converter.
 * This CES converter is used for 16 bit CCSes which include 7bit
 * Portable Characters Set (PCS) (equivalent to ASCII) (example: BIG5).
 */

#include "cesbi.h"

#if defined (ICONV_TO_UCS_CES_TABLE_PCS) \
 || defined (ICONV_FROM_UCS_CES_TABLE_PCS)

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include "../lib/local.h"
#include "../lib/ucsconv.h"

#if defined (ICONV_FROM_UCS_CES_TABLE_PCS)
static size_t
_DEFUN(table_pcs_convert_from_ucs, (data, in, outbuf, outbytesleft),
                               _VOID_PTR data         _AND
                               ucs4_t in              _AND
                               unsigned char **outbuf _AND
                               size_t *outbytesleft)
{
  if (*outbytesleft < 1)
    return (size_t)ICONV_CES_NOSPACE;
    
  if (in  < 0x80)
    {
      **outbuf = (unsigned char)in;
      *outbuf += 1;
      *outbytesleft -= 1;
      return 1;
    }

  return _iconv_from_ucs_ces_handlers_table.convert_from_ucs (
                                                    data,
                                                    in,
                                                    outbuf,
                                                    outbytesleft);
}

static _VOID_PTR
_DEFUN(table_pcs_from_ucs_init, (rptr, encoding),
                                struct _reent *rptr _AND
                                _CONST char *encoding)
{
  return _iconv_from_ucs_ces_handlers_table.init (rptr, encoding);
}

static size_t
_DEFUN(table_pcs_from_ucs_close, (rptr, data),
                                 struct _reent *rptr _AND
                                 _VOID_PTR data)
{
  return _iconv_from_ucs_ces_handlers_table.close (rptr, data);
}

static int
_DEFUN(table_pcs_from_ucs_get_mb_cur_max, (data),
                                           _VOID_PTR data)
{
  return _iconv_from_ucs_ces_handlers_table.get_mb_cur_max (data);
}

#endif /* ICONV_FROM_UCS_CES_TABLE_PCS */

#if defined (ICONV_TO_UCS_CES_TABLE_PCS)
static ucs4_t
_DEFUN(table_pcs_convert_to_ucs, (data, inbuf, inbytesleft),
                             _VOID_PTR data               _AND
                             _CONST unsigned char **inbuf _AND
                             size_t *inbytesleft)
{
  if (*inbytesleft < 1)
    return (ucs4_t)ICONV_CES_BAD_SEQUENCE;

  if (**inbuf < 0x80)
    {
      *inbytesleft -= 1;
      *inbuf += 1;
      return (ucs4_t)(*(*inbuf - 1));
    }
    
  return _iconv_to_ucs_ces_handlers_table.convert_to_ucs (
                                                             data,
                                                             inbuf,
                                                             inbytesleft);
}

static _VOID_PTR
_DEFUN(table_pcs_to_ucs_init, (rptr, encoding),
                              struct _reent *rptr _AND
                              _CONST char *encoding)
{
  return _iconv_to_ucs_ces_handlers_table.init (rptr, encoding);
}

static size_t
_DEFUN(table_pcs_to_ucs_close, (rptr, data),
                               struct _reent *rptr _AND
                               _VOID_PTR data)
{
  return _iconv_to_ucs_ces_handlers_table.close (rptr, data);
}

static int
_DEFUN(table_pcs_to_ucs_get_mb_cur_max, (data),
                                         _VOID_PTR data)
{
  return _iconv_to_ucs_ces_handlers_table.get_mb_cur_max (data);
}

#endif /* ICONV_TO_UCS_CES_TABLE_PCS */

#if defined (ICONV_FROM_UCS_CES_TABLE_PCS)
_CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_table_pcs =
{
  table_pcs_from_ucs_init,
  table_pcs_from_ucs_close,
  table_pcs_from_ucs_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  table_pcs_convert_from_ucs
};
#endif

#if defined (ICONV_TO_UCS_CES_TABLE_PCS)
_CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_table_pcs = 
{
  table_pcs_to_ucs_init,
  table_pcs_to_ucs_close,
  table_pcs_to_ucs_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  table_pcs_convert_to_ucs
};
#endif

#endif /* ICONV_TO_UCS_CES_TABLE_PCS || ICONV_FROM_UCS_CES_TABLE_PCS */


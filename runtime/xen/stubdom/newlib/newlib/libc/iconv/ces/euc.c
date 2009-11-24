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

#if defined (ICONV_TO_UCS_CES_EUC) \
 || defined (ICONV_FROM_UCS_CES_EUC)

#include <_ansi.h>
#include <reent.h>
#include <newlib.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <sys/types.h>
#include "../lib/local.h"
#include "../lib/ucsconv.h"
#include "../lib/encnames.h"
#include "../ccs/ccsnames.h"

#define TYPE_EUC_JP 0
#define TYPE_EUC_KR 1
#define TYPE_EUC_TW 2

#define MAX_CS_NUM 3
  
/* CS  description structure */ 
typedef struct
{
  char *csname;
  char *prefix;
  int bytes;
  int prefixbytes;
  int touchmsb; /* If 1, msb will be set by euc converter */
} euc_cs_desc_t;

typedef struct
{ 
  int type;
  int mb_cur_max;
  euc_cs_desc_t *desc;
  
  _VOID_PTR data[MAX_CS_NUM];
} euc_data_t;

#if defined (_ICONV_TO_ENCODING_EUC_JP) \
 || defined (_ICONV_FROM_ENCODING_EUC_JP) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
static euc_cs_desc_t euc_jp_cs_desc[] =
{
  {ICONV_CCS_JIS_X0208_1990, "",     2, 0, 1},
  {ICONV_CCS_JIS_X0201_1976, "\x8e", 1, 1, 0},
  {ICONV_CCS_JIS_X0212_1990, "\x8f", 2, 1, 1},
  {NULL, NULL, 0, 0}
};
#endif

#if defined (_ICONV_TO_ENCODING_EUC_TW) \
 || defined (_ICONV_FROM_ENCODING_EUC_TW) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
static euc_cs_desc_t euc_tw_cs_desc [] =
{
  {ICONV_CCS_CNS11643_PLANE1,  "",         2, 0, 1},
  {ICONV_CCS_CNS11643_PLANE2,  "\x8e\xa2", 2, 2, 1},
  {ICONV_CCS_CNS11643_PLANE14, "\x8e\xae", 2, 2, 1},
  {NULL, NULL, 0, 0}
};
#endif

#if defined (_ICONV_TO_ENCODING_EUC_KR) \
 || defined (_ICONV_FROM_ENCODING_EUC_KR) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
static euc_cs_desc_t euc_kr_cs_desc [] =
{
  {ICONV_CCS_KSX1001,  "", 2, 0, 1},
  {NULL, NULL, 0, 0}
};
#endif

#if defined (ICONV_FROM_UCS_CES_EUC)
static _VOID_PTR
_DEFUN(euc_from_ucs_init, (rptr, encoding),
                          struct _reent *rptr _AND
                          _CONST char *encoding)
{
  int i;
  euc_data_t *data;

  if ((data = (euc_data_t *)_calloc_r (rptr, 1, sizeof (euc_data_t))) == NULL)
    return 0;
  
#if defined (_ICONV_TO_ENCODING_EUC_JP) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
  if (strcmp (encoding, ICONV_ENCODING_EUC_JP) == 0)
    {
      data->type = TYPE_EUC_JP;
      data->mb_cur_max = 3;
      data->desc = &euc_jp_cs_desc[0];
      goto ok;
    }
#endif
#if defined (_ICONV_TO_ENCODING_EUC_KR) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
  if (strcmp (encoding, ICONV_ENCODING_EUC_KR) == 0)
    {
      data->type = TYPE_EUC_KR;
      data->mb_cur_max = 2;
      data->desc = &euc_kr_cs_desc[0];
      goto ok;
    }
#endif
#if defined (_ICONV_TO_ENCODING_EUC_TW) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
  if (strcmp (encoding, ICONV_ENCODING_EUC_TW) == 0)
    {
      data->type = TYPE_EUC_TW;
      data->mb_cur_max = 4;
      data->desc = &euc_tw_cs_desc[0];
      goto ok;
    }
#endif
 
  goto error1;

ok:
  for (i = 0; data->desc[i].csname != NULL; i++)
    {
      data->data[i] = _iconv_from_ucs_ces_handlers_table.init (
                                                        rptr,
                                                        data->desc[i].csname);
      if (data->data == NULL)
        goto error;
    } 

  return data;
    
error:
  _iconv_from_ucs_ces_handlers_table.close (rptr, data);
  return NULL;
error1:
  _free_r (rptr, (_VOID_PTR)data);
  return NULL;
}

static size_t
_DEFUN(euc_from_ucs_close, (rptr, data),
                           struct _reent *rptr _AND
                           _VOID_PTR data)
{
  int i;
  size_t res = 0;
  
  for (i = 0; i < MAX_CS_NUM; i++)
    {
      if (((euc_data_t *)data)->data[i] != NULL)
        res |= _iconv_from_ucs_ces_handlers_table.close (
                                                rptr,
                                                ((euc_data_t *)data)->data[i]);
    }
  _free_r(rptr, data);

  return res;
}

static size_t
_DEFUN(euc_convert_from_ucs, (data, in, outbuf, outbytesleft),
                             _VOID_PTR data         _AND
                             register ucs4_t in     _AND
                             unsigned char **outbuf _AND
                             size_t *outbytesleft)
{
  int i;
  int j;
  int res;
  unsigned char *outbuf1;
  size_t outbytesleft1;
  euc_data_t *d = (euc_data_t *)data;

  if (in < 0x80) /* CS0 ASCII */
    return _iconv_from_ucs_ces_handlers_us_ascii.convert_from_ucs (
                                                 NULL,
                                                 in,
                                                 outbuf,
                                                 outbytesleft);
      
  /* Try other CS */
  for (i = 0; d->desc[i].csname != NULL; i++) 
    {
      
      if (((int)*outbytesleft - d->desc[i].prefixbytes - d->desc[i].bytes) < 0)
        {
          char buf[ICONV_MB_LEN_MAX];
          outbytesleft1 = ICONV_MB_LEN_MAX;
          outbuf1 = &buf[0];
          /* See wether this is right sequence */
          res = 
            (int)_iconv_from_ucs_ces_handlers_table.convert_from_ucs (
                                                         d->data[i],
                                                         in,
                                                         &outbuf1,
                                                         &outbytesleft1);
          if (res > 0)
            return (size_t)ICONV_CES_NOSPACE;

          continue;
        }
      
      outbuf1 = *outbuf + d->desc[i].prefixbytes;
      outbytesleft1 = *outbytesleft - d->desc[i].prefixbytes;
      
      res = (int)_iconv_from_ucs_ces_handlers_table.convert_from_ucs (
                                                     d->data[i],
                                                     in,
                                                     &outbuf1,
                                                     &outbytesleft1);
      if (res == d->desc[i].bytes)
        {
          for (j = 0; j < d->desc[i].prefixbytes; j++)
            (*outbuf)[j] = d->desc[i].prefix[j];

          if (d->desc[i].touchmsb)
            for (j = 0; j < d->desc[i].bytes; j++)
              {
                if ((*outbuf)[j + d->desc[i].prefixbytes] & 0x80)
                  return (size_t)ICONV_CES_INVALID_CHARACTER;
                (*outbuf)[j + d->desc[i].prefixbytes] |= 0x80;
              }

          *outbuf = outbuf1;
          *outbytesleft = outbytesleft1;
          
          return (size_t)(res + d->desc[i].bytes);
        }
    }

  return (size_t)ICONV_CES_INVALID_CHARACTER;
}
#endif /* ICONV_FROM_UCS_CES_EUC */

#if defined (ICONV_TO_UCS_CES_EUC)
static _VOID_PTR
_DEFUN(euc_to_ucs_init, (rptr, encoding),
                        struct _reent *rptr _AND
                        _CONST char *encoding)
{
  int i;
  euc_data_t *data;

  if ((data = (euc_data_t *)_calloc_r (rptr, 1, sizeof (euc_data_t))) == NULL)
    return 0;
  
#if defined (_ICONV_TO_ENCODING_EUC_JP) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
  if (strcmp (encoding, ICONV_ENCODING_EUC_JP) == 0)
    {
      data->type = TYPE_EUC_JP;
      data->mb_cur_max = 3;
      data->desc = &euc_jp_cs_desc[0];
      goto ok;
    }
#endif
#if defined (_ICONV_TO_ENCODING_EUC_KR) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
  if (strcmp (encoding, ICONV_ENCODING_EUC_KR) == 0)
    {
      data->type = TYPE_EUC_KR;
      data->mb_cur_max = 2;
      data->desc = &euc_kr_cs_desc[0];
      goto ok;
    }
#endif
#if defined (_ICONV_TO_ENCODING_EUC_TW) \
 || defined (_ICONV_ENABLE_EXTERNAL_CCS)
  if (strcmp (encoding, ICONV_ENCODING_EUC_TW) == 0)
    {
      data->type = TYPE_EUC_TW;
      data->mb_cur_max = 4;
      data->desc = &euc_tw_cs_desc[0];
      goto ok;
    }
#endif
 
  goto error1;

ok:
  for (i = 0; data->desc[i].csname != NULL; i++)
    {
      data->data[i] = _iconv_to_ucs_ces_handlers_table.init (
                                                        rptr,
                                                        data->desc[i].csname);
      if (data->data == NULL)
        goto error;
    } 

  return data;
    
error:
  _iconv_to_ucs_ces_handlers_table.close (rptr, data);
  return NULL;
error1:
  _free_r (rptr, (_VOID_PTR)data);
  return NULL;
}

static size_t
_DEFUN(euc_to_ucs_close, (rptr, data),
                         struct _reent *rptr _AND
                         _VOID_PTR data)
{
  int i;
  size_t res = 0;
  
  for (i = 0; i < MAX_CS_NUM; i++)
    {
      if (((euc_data_t *)data)->data[i] != NULL)
        res |= _iconv_to_ucs_ces_handlers_table.close (
                                                rptr,
                                                ((euc_data_t *)data)->data[i]);
    }
  _free_r(rptr, data);

  return res;
}

static ucs4_t
_DEFUN(euc_convert_to_ucs, (data, inbuf, inbytesleft),
                           _VOID_PTR data               _AND
                           _CONST unsigned char **inbuf _AND
                           size_t *inbytesleft)
{
  int i;
  int j;
  ucs4_t res;
  unsigned char buf[ICONV_MB_LEN_MAX];
  size_t inbytesleft1;
  euc_data_t *d = (euc_data_t *)data;
  unsigned char *inbuf1 = &buf[0];
  
  if (**inbuf < 0x80) /* CS0 is always ASCII */
    return _iconv_to_ucs_ces_handlers_us_ascii.convert_to_ucs (
                                                         NULL,
                                                         inbuf,
                                                         inbytesleft);
 
  for (i = 1; d->desc[i].csname != NULL; i++)
    {
      if (memcmp((_CONST _VOID_PTR)(*inbuf),
                 (_CONST _VOID_PTR)d->desc[i].prefix,
                 d->desc[i].prefixbytes) == 0)
        {
          if (((int)*inbytesleft - d->desc[i].prefixbytes - d->desc[i].bytes) < 0)
            return (ucs4_t)ICONV_CES_BAD_SEQUENCE;

          if (d->desc[i].touchmsb)
            for (j = 0; j < d->desc[i].bytes; j++)
              {
                if (!((*inbuf)[j + d->desc[i].prefixbytes] & 0x80))
                  return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
                inbuf1[j] = (*inbuf)[j + d->desc[i].prefixbytes] & 0x7F;
              }
          else
            for (j = 0; j < d->desc[i].bytes; j++)
              inbuf1[j] = (*inbuf)[j + d->desc[i].prefixbytes];
          
          inbytesleft1 = d->desc[i].bytes;
          
          res = _iconv_to_ucs_ces_handlers_table.convert_to_ucs (
                                             d->data[i],
                                             (_CONST unsigned char **)&inbuf1,
                                             &inbytesleft1);
          if (((__int32_t)res) > 0)
            {
              *inbuf += d->desc[i].bytes +  d->desc[i].prefixbytes;
              *inbytesleft -= d->desc[i].bytes + d->desc[i].prefixbytes;
            }

          return res;
        }
    }

  /* Process CS1 */
  if (((int)(*inbytesleft - d->desc[0].prefixbytes - d->desc[0].bytes)) < 0)
    return (ucs4_t)ICONV_CES_BAD_SEQUENCE;
  
  if (d->desc[0].touchmsb)
    for (j = 0; j < d->desc[0].bytes; j++)
      {
        if (!((*inbuf)[j + d->desc[0].prefixbytes] & 0x80))
          return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
        inbuf1[j] = (*inbuf)[j] & 0x7F;
      }
  else
    for (j = 0; j < d->desc[0].bytes; j++)
      inbuf1[j] = (*inbuf)[j];

  inbytesleft1 = d->desc[0].bytes;
  
  res = _iconv_to_ucs_ces_handlers_table.convert_to_ucs (
                                        d->data[0],
                                        (_CONST unsigned char **)&inbuf1,
                                        &inbytesleft1);
  if (((__int32_t)res) > 0)
    {
      *inbuf += d->desc[0].bytes;
      *inbytesleft -= d->desc[0].bytes;
    }

  return res;
}
#endif /* ICONV_TO_UCS_CES_EUC */

static int
_DEFUN(euc_get_mb_cur_max, (data),
                           _VOID_PTR data)
{
  return ((euc_data_t *)data)->mb_cur_max;
}

#if defined (ICONV_FROM_UCS_CES_EUC)
_CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_euc =
{
  euc_from_ucs_init,
  euc_from_ucs_close,
  euc_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  euc_convert_from_ucs
};
#endif

#if defined (ICONV_TO_UCS_CES_EUC)
_CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_euc = 
{
  euc_to_ucs_init,
  euc_to_ucs_close,
  euc_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  euc_convert_to_ucs
};
#endif

#endif /* ICONV_TO_UCS_CES_EUC || ICONV_FROM_UCS_CES_EUC */



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

#if defined (ICONV_TO_UCS_CES_TABLE) \
 || defined (ICONV_FROM_UCS_CES_TABLE)
 
#include <_ansi.h>
#include <reent.h>
#include <newlib.h>
#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/iconvnls.h>
#include "../lib/endian.h"
#include "../lib/local.h"
#include "../lib/ucsconv.h"
#include "../ccs/ccs.h"

/*
 * Table-based CES converter is implemented here.  Table-based CES converter
 * deals with encodings with "null" CES, like KOI8-R. In this case it is
 * possible to implement one generic algorithm which works with different
 * CCS tables.
 *
 * Table-based CES converter deals with CCS tables placed into iconv/ccs
 * subdirectory. First, converter tries to find needed CCS table among
 * linked-in tables. If not found, it tries to load it from external file
 * (only if corespondent capability was enabled in Newlib configuration). 
 *
 * 16 bit encodings are assumed to be Big Endian.
 */

static ucs2_t
_EXFUN(find_code_size, (ucs2_t code, _CONST __uint16_t *tblp));

static __inline ucs2_t
_EXFUN(find_code_speed, (ucs2_t code, _CONST __uint16_t *tblp));

static __inline ucs2_t
_EXFUN(find_code_speed_8bit, (ucs2_t code, _CONST unsigned char *tblp));

#ifdef _ICONV_ENABLE_EXTERNAL_CCS
static _CONST iconv_ccs_desc_t *
_EXFUN(load_file, (struct _reent *rptr, _CONST char *name, int direction));
#endif

/*
 * Interface data and functions implementation.
 */
static size_t
_DEFUN(table_close, (rptr, data),
                    struct _reent *rptr _AND
                    _VOID_PTR data)
{
  _CONST iconv_ccs_desc_t *ccsp = (iconv_ccs_desc_t *)data;

  if (ccsp->type == TABLE_EXTERNAL)
    _free_r (rptr, (_VOID_PTR)ccsp->tbl);

  _free_r( rptr, (_VOID_PTR)ccsp);
  return 0;
}

#if defined (ICONV_FROM_UCS_CES_TABLE)
static _VOID_PTR
_DEFUN(table_init_from_ucs, (rptr, encoding),
                            struct _reent *rptr _AND
                            _CONST char *encoding)
{
  int i;
  _CONST iconv_ccs_t *biccsp = NULL;
  iconv_ccs_desc_t *ccsp;
  
  for (i = 0; _iconv_ccs[i] != NULL; i++)
    if (strcmp (_iconv_ccs[i]->name, encoding) == 0)
      {
        biccsp = _iconv_ccs[i]; 
        break;
      }

  if (biccsp != NULL)
    {
      if (biccsp->from_ucs == NULL
          || (ccsp = (iconv_ccs_desc_t *)
                     _malloc_r (rptr, sizeof (iconv_ccs_desc_t))) == NULL)
        return NULL;

      ccsp->type = TABLE_BUILTIN;
      ccsp->bits = biccsp->bits;
      ccsp->optimization = biccsp->from_ucs_type;
      ccsp->tbl = biccsp->from_ucs;
      
      return (_VOID_PTR)ccsp;
    }
    
#ifdef _ICONV_ENABLE_EXTERNAL_CCS
  return (_VOID_PTR)load_file (rptr, encoding, 1);
#else
  return NULL;
#endif
}

static size_t
_DEFUN(table_convert_from_ucs, (data, in, outbuf, outbytesleft),
                               _VOID_PTR data         _AND
                               ucs4_t in              _AND
                               unsigned char **outbuf _AND
                               size_t *outbytesleft)
{
  _CONST iconv_ccs_desc_t *ccsp = (iconv_ccs_desc_t *)data;
  ucs2_t code;

  if (in > 0xFFFF || in == INVALC)
    return (size_t)ICONV_CES_INVALID_CHARACTER;

  if (ccsp->bits == TABLE_8BIT)
    {
      code = find_code_speed_8bit ((ucs2_t)in,
                                  (_CONST unsigned char *)ccsp->tbl);
      if (code == INVALC)
        return (size_t)ICONV_CES_INVALID_CHARACTER;
      **outbuf = (unsigned char)code;
      *outbuf += 1;
      *outbytesleft -= 1;
      return 1; 
    }
  else if (ccsp->optimization == TABLE_SPEED_OPTIMIZED)
    code = find_code_speed ((ucs2_t)in, ccsp->tbl);
  else
    code = find_code_size ((ucs2_t)in, ccsp->tbl);

  if (code == INVALC)
    return (size_t)ICONV_CES_INVALID_CHARACTER;

  if (*outbytesleft < 2)
    return (size_t)ICONV_CES_NOSPACE;
  
  /* We can't store whole word since **outbuf may be not 2-byte aligned */
  **outbuf = (unsigned char)((ucs2_t)code >> 8);
  *(*outbuf + 1) = (unsigned char)code;
  *outbuf += 2;
  *outbytesleft -= 2;
  return 2; 
}
#endif /* ICONV_FROM_UCS_CES_TABLE */

#if defined (ICONV_TO_UCS_CES_TABLE)
static _VOID_PTR
_DEFUN(table_init_to_ucs, (rptr, encoding),
                          struct _reent *rptr _AND
                          _CONST char *encoding)
{
  int i;
  _CONST iconv_ccs_t *biccsp = NULL;
  iconv_ccs_desc_t *ccsp;
  
  for (i = 0; _iconv_ccs[i] != NULL; i++)
    if (strcmp (_iconv_ccs[i]->name, encoding) == 0)
      {
        biccsp = _iconv_ccs[i]; 
        break;
      }

  if (biccsp != NULL)
    {
      if (biccsp->to_ucs == NULL
          || (ccsp = (iconv_ccs_desc_t *)
                     _malloc_r (rptr, sizeof (iconv_ccs_desc_t))) == NULL)
        return NULL;

      ccsp->type = TABLE_BUILTIN;
      ccsp->bits = biccsp->bits;
      ccsp->optimization = biccsp->to_ucs_type;
      ccsp->tbl = biccsp->to_ucs;
      
      return (_VOID_PTR)ccsp;
    }
  
#ifdef _ICONV_ENABLE_EXTERNAL_CCS
  return (_VOID_PTR)load_file (rptr, encoding, 0);
#else
  return NULL;
#endif
}

static ucs4_t
_DEFUN(table_convert_to_ucs, (data, inbuf, inbytesleft),
                             _VOID_PTR data               _AND
                             _CONST unsigned char **inbuf _AND
                             size_t *inbytesleft)
{
  _CONST iconv_ccs_desc_t *ccsp = (iconv_ccs_desc_t *)data;
  ucs2_t ucs;
  
  if (ccsp->bits == TABLE_8BIT)
    {
      if (*inbytesleft < 1)
        return (ucs4_t)ICONV_CES_BAD_SEQUENCE;
  
      ucs = (ucs2_t)ccsp->tbl[**inbuf];
      
      if (ucs == INVALC)
        return (ucs4_t)ICONV_CES_INVALID_CHARACTER;
         
      *inbytesleft -= 1;
      *inbuf += 1;
      return (ucs4_t)ucs; 
    }

  if (*inbytesleft < 2)
    return (ucs4_t)ICONV_CES_BAD_SEQUENCE;

  if (ccsp->optimization == TABLE_SIZE_OPTIMIZED)
    ucs = find_code_size((ucs2_t)**inbuf << 8 | (ucs2_t)*(*inbuf + 1),
                         ccsp->tbl);
  else
    ucs = find_code_speed((ucs2_t)**inbuf << 8 | (ucs2_t)*(*inbuf + 1),
                          ccsp->tbl);

  if (ucs == INVALC)
    return (ucs4_t)ICONV_CES_INVALID_CHARACTER;

  *inbuf += 2;
  *inbytesleft -= 2;
  return (ucs4_t)ucs; 
}
#endif /* ICONV_TO_UCS_CES_TABLE */

static int
_DEFUN(table_get_mb_cur_max, (data),
                             _VOID_PTR data)
{
  return ((iconv_ccs_desc_t *)data)->bits/8;
}


#if defined (ICONV_TO_UCS_CES_TABLE)
_CONST iconv_to_ucs_ces_handlers_t
_iconv_to_ucs_ces_handlers_table = 
{
  table_init_to_ucs,
  table_close,
  table_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  table_convert_to_ucs
};
#endif /* ICONV_FROM_UCS_CES_TABLE */

#if defined (ICONV_FROM_UCS_CES_TABLE)
_CONST iconv_from_ucs_ces_handlers_t
_iconv_from_ucs_ces_handlers_table =
{
  table_init_from_ucs,
  table_close,
  table_get_mb_cur_max,
  NULL,
  NULL,
  NULL,
  table_convert_from_ucs
};
#endif /* ICONV_TO_UCS_CES_TABLE */

/*
 * Supplementary functions.
 */

/*
 * find_code_speed - find code in 16 bit speed-optimized table.
 *
 * PARAMETERS:
 *     ucs2_t code - code whose mapping to find.
 *     _CONST __uint16_t *tblp - table pointer.
 *
 * RETURN:
 *     Code that corresponds to 'code'.
 */
static __inline ucs2_t
_DEFUN(find_code_speed, (code, tblp),
                        ucs2_t code _AND
                        _CONST __uint16_t *tblp)
{
  int idx = tblp[code >> 8];

  if (idx == INVBLK)
    return (ucs2_t)INVALC;

  return (ucs2_t)tblp[(code & 0x00FF) + idx];
}

/*
 * find_code_speed_8bit - find code in 8 bit speed-optimized table.
 *
 * PARAMETERS:
 *     ucs2_t code - code whose mapping to find.
 *     _CONST __uint16_t *tblp - table pointer.
 *
 * RETURN:
 *     Code that corresponds to 'code'.
 */
static __inline ucs2_t
_DEFUN(find_code_speed_8bit, (code, tblp),
                             ucs2_t code _AND
                             _CONST unsigned char *tblp)
{
  int idx;
  unsigned char ccs;

  if (code == ((ucs2_t *)tblp)[0])
    return (ucs2_t)0xFF;
 
  idx = ((ucs2_t *)tblp)[1 + (code >> 8)];
  
  if (idx == INVBLK)
    return (ucs2_t)INVALC;

  ccs = tblp[(code & 0x00FF) + idx];

  return ccs == 0xFF ? (ucs2_t)INVALC : (ucs2_t)ccs;
}

/* Left range boundary */
#define RANGE_LEFT(n)     (tblp[FIRST_RANGE_INDEX + (n)*3 + 0])
/* Right range boundary */
#define RANGE_RIGHT(n)    (tblp[FIRST_RANGE_INDEX + (n)*3 + 1])
/* Range offset */
#define RANGE_INDEX(n)    (tblp[FIRST_RANGE_INDEX + (n)*3 + 2])
/* Un-ranged offset */
#define UNRANGED_INDEX(n) (tblp[FIRST_UNRANGED_INDEX_INDEX] + (n)*2)

/*
 * find_code_size - find code in 16 bit size-optimized table.
 *
 * PARAMETERS:
 *     ucs2_t code - code whose mapping to find.
 *     _CONST __uint16_t *tblp - table pointer.
 *
 * RETURN:
 *     Code that corresponds to 'code'.
 */
static ucs2_t
_DEFUN(find_code_size, (code, tblp),
                       ucs2_t code _AND
                       _CONST __uint16_t *tblp)
{
  int first, last, cur, center;

  if (tblp[RANGES_NUM_INDEX] > 0)
    {
      first = 0;
      last = tblp[RANGES_NUM_INDEX] - 1;
 
      do
        {
          center = (last - first)/2;
          cur = center + first;
          
          if (code > RANGE_RIGHT (cur))
            first = cur;
          else if (code < RANGE_LEFT (cur))
            last = cur;
          else
            return (ucs2_t)tblp[RANGE_INDEX (cur) + code - RANGE_LEFT (cur)];
        } while (center > 0);

        if (last - first == 1)
          {
            if (code >= RANGE_LEFT (first) && code <= RANGE_RIGHT (first))
              return (ucs2_t)tblp[RANGE_INDEX (first)
                                  + code - RANGE_LEFT (first)];
            if (code >= RANGE_LEFT (last) && code <= RANGE_RIGHT (last))
              return (ucs2_t)tblp[RANGE_INDEX (last)
                                  + code - RANGE_LEFT (last)];
          }
    }
  
  if (tblp[UNRANGED_NUM_INDEX] > 0)
    {
      first = 0;
      last = tblp[UNRANGED_NUM_INDEX] - 1;
 
      do
        {
          int c;

          center = (last - first)/2;
          cur = center + first;
          c = tblp[UNRANGED_INDEX (cur)];
 
          if (code > c)
            first = cur;
          else if (code < c)
            last = cur;
          else
            return (ucs2_t)tblp[UNRANGED_INDEX (cur) + 1];
        } while (center > 0);

        if (last - first == 1)
          {
            if (code == tblp[UNRANGED_INDEX (first)])
              return (ucs2_t)tblp[UNRANGED_INDEX (first) + 1];
            if (code == tblp[UNRANGED_INDEX (last)])
              return (ucs2_t)tblp[UNRANGED_INDEX (last) + 1];
          }
    }

  return (ucs2_t)INVALC;
}

#ifdef _ICONV_ENABLE_EXTERNAL_CCS

#define _16BIT_ELT(offset) \
    ICONV_BETOHS(*((__uint16_t *)(buf + (offset))))
#define _32BIT_ELT(offset) \
    ICONV_BETOHL(*((__uint32_t *)(buf + (offset))))

/*
 * load_file - load conversion table from external file and initialize
 *             iconv_ccs_desc_t object.
 *
 * PARAMETERS:
 *    struct _reent *rptr - reent structure of current thread/process.
 *    _CONST char *name - encoding name.
 *    int direction - conversion direction.
 *
 * DESCRIPTION:
 *    Loads conversion table of appropriate endianess from external file
 *    and initializes 'iconv_ccs_desc_t' table description structure.
 *    If 'direction' is 0 - load "To UCS" table, else load "From UCS"
 *    table.
 *
 * RETURN:
 *    iconv_ccs_desc_t * pointer is success, NULL if failure.
 */
static _CONST iconv_ccs_desc_t *
_DEFUN(load_file, (rptr, name, direction), 
                  struct _reent *rptr _AND
                  _CONST char *name   _AND
                  int direction)
{
  int fd;
  _CONST unsigned char *buf;
  int tbllen, hdrlen;
  off_t off;
  _CONST char *fname;
  iconv_ccs_desc_t *ccsp = NULL;
  int nmlen = strlen(name);
  /* Since CCS table name length can vary - it is aligned (by adding extra
   * bytes to it's end) to 4-byte boundary. */
  int alignment = nmlen & 3 ? 4 - (nmlen & 3) : 0;
  
  nmlen = strlen(name);
  
  hdrlen = nmlen + EXTTABLE_HEADER_LEN + alignment;

  if ((fname = _iconv_nls_construct_filename (rptr, name, ICONV_SUBDIR,
                                              ICONV_DATA_EXT)) == NULL)
    return NULL;
  
  if ((fd = _open_r (rptr, fname, O_RDONLY, S_IRUSR)) == -1)
    goto error1;
  
  if ((buf = (_CONST unsigned char *)_malloc_r (rptr, hdrlen)) == NULL)
    goto error2;

  if (_read_r (rptr, fd, (_VOID_PTR)buf, hdrlen) != hdrlen)
    goto error3;

  if (_16BIT_ELT (EXTTABLE_VERSION_OFF) != TABLE_VERSION_1
      || _32BIT_ELT (EXTTABLE_CCSNAME_LEN_OFF) != nmlen
      || strncmp (buf + EXTTABLE_CCSNAME_OFF, name, nmlen) != 0)
    goto error3; /* Bad file */

  if ((ccsp = (iconv_ccs_desc_t *)
           _calloc_r (rptr, 1, sizeof (iconv_ccs_desc_t))) == NULL)
    goto error3;
  
  ccsp->bits = _16BIT_ELT (EXTTABLE_BITS_OFF);
  ccsp->type = TABLE_EXTERNAL;

  /* Add 4-byte alignment to name length */
  nmlen += alignment;

  if (ccsp->bits == TABLE_8BIT)
    {
      if (direction == 0) /* Load "To UCS" table */
        {
          off = (off_t)_32BIT_ELT (nmlen + EXTTABLE_TO_SPEED_OFF);
          tbllen = _32BIT_ELT (nmlen + EXTTABLE_TO_SPEED_LEN_OFF);
        }
      else /* Load "From UCS" table */
        {
          off = (off_t)_32BIT_ELT (nmlen + EXTTABLE_FROM_SPEED_OFF);
          tbllen = _32BIT_ELT (nmlen + EXTTABLE_FROM_SPEED_LEN_OFF);
        }
    }
  else if (ccsp->bits == TABLE_16BIT)
    {
      if (direction == 0) /* Load "To UCS" table */
        {
#ifdef TABLE_USE_SIZE_OPTIMIZATION
          off = (off_t)_32BIT_ELT (nmlen + EXTTABLE_TO_SIZE_OFF);
          tbllen = _32BIT_ELT (nmlen + EXTTABLE_TO_SIZE_LEN_OFF);
#else
          off = (off_t)_32BIT_ELT (nmlen + EXTTABLE_TO_SPEED_OFF);
          tbllen = _32BIT_ELT (nmlen + EXTTABLE_TO_SPEED_LEN_OFF);
#endif
        }
      else /* Load "From UCS" table */
        {
#ifdef TABLE_USE_SIZE_OPTIMIZATION
          off = (off_t)_32BIT_ELT (nmlen + EXTTABLE_FROM_SIZE_OFF);
          tbllen = _32BIT_ELT (nmlen + EXTTABLE_FROM_SIZE_LEN_OFF);
#else
          off = (off_t)_32BIT_ELT (nmlen + EXTTABLE_FROM_SPEED_OFF);
          tbllen = _32BIT_ELT (nmlen + EXTTABLE_FROM_SPEED_LEN_OFF);
#endif
        }
#ifdef TABLE_USE_SIZE_OPTIMIZATION
      ccsp->optimization = TABLE_SIZE_OPTIMIZED; 
#else
      ccsp->optimization = TABLE_SPEED_OPTIMIZED;
#endif
    }
  else
    goto error4; /* Bad file */

  if (off == EXTTABLE_NO_TABLE)
    goto error4; /* No correspondent table in file */

  if ((ccsp->tbl = (ucs2_t *)_malloc_r (rptr, tbllen)) == NULL)
    goto error4;

  if (_lseek_r (rptr, fd, off, SEEK_SET) == (off_t)-1
      || _read_r (rptr, fd, (_VOID_PTR)ccsp->tbl, tbllen) != tbllen)
    goto error5;

  goto normal_exit;

error5:
  _free_r (rptr, (_VOID_PTR)ccsp->tbl);
  ccsp->tbl = NULL;
error4:
  _free_r (rptr, (_VOID_PTR)ccsp);
  ccsp = NULL;
error3:
normal_exit:
  _free_r (rptr, (_VOID_PTR)buf);
error2:
  if (_close_r (rptr, fd) == -1)
    {
      if (ccsp != NULL)
        {
          if (ccsp->tbl != NULL)
            _free_r (rptr, (_VOID_PTR)ccsp->tbl);
          _free_r (rptr, (_VOID_PTR)ccsp);
        }
      ccsp = NULL;
    }
error1:
  _free_r (rptr, (_VOID_PTR)fname);
  return ccsp;
}
#endif

#endif /* ICONV_TO_UCS_CES_TABLE || ICONV_FROM_UCS_CES_TABLE */


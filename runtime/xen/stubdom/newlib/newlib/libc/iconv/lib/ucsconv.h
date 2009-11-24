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
#ifndef __ICONV_UCS_CONVERSION_H__
#define __ICONV_UCS_CONVERSION_H__

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include <wchar.h>
#include "local.h"

/* No enough space in output buffer */
#define ICONV_CES_NOSPACE 0
/* Invalid input character */
#define ICONV_CES_INVALID_CHARACTER -1
/* No corespondent character in destination encoding */
#define ICONV_CES_BAD_SEQUENCE -2
/* All unknown characters are marked by this code */
#define DEFAULT_CHARACTER 0x3f /* ASCII '?' */


/*
 * iconv_to_ucs_ces_handlers_t - "to UCS" CES converter handlers.
 *
 * Structure contains function pointers which should be provided by
 * "to_ucs" CES converter.
 *
 * ============================================================================
 */
typedef struct
{
  /*
   * init - initialize CES converter.
   *
   * PARAMETERS:
   *   struct _reent *rptr   - reent structure of current thread/process;
   *   _CONST char *encoding - encoding name.
   *
   * DESCRIPTION:
   *  Initializes CES converter. CES converter may deal with a series of
   *  encodings, such as Table or EUC CES converters. 'encoding' parameter
   *  indicates which encoding CES converter should use.
   *
   * RETURN:
   *   Returns CES-specific data pointer if success. In case of error returns
   *   NULL and sets current thread's/process's errno.
   */
  _VOID_PTR _EXPARM(init, (struct _reent *rptr,
                          _CONST char *encoding));

  /*
   * close - close CES converter.
   *
   * PARAMETERS:
   *   struct _reent *rptr - reent structure of current thread/process;
   *   _VOID_PTR data      - CES converter-specific data.
   *
   * DESCRIPTION:
   *     Preforms CES converter closing.   *
   * RETURN:
   *   Returns (size_t)0 if success. In case of error returns (size_t)-1 and
   *   sets current thread's/process's errno.
   */
  size_t _EXPARM(close, (struct _reent *rptr,
                        _VOID_PTR data));

  /*
   * get_mb_cur_max - get maximum character length in bytes.
   *
   * PARAMETERS:
   *   _VOID_PTR data     - conversion-specific data;
   *
   * DESCRIPTION:
   *   Returns encoding's maximum character length.
   */
  int _EXPARM(get_mb_cur_max, (_VOID_PTR data));
  
  /*
   * get_state - get current shift state.
   *
   * PARAMETERS:
   *   _VOID_PTR data   - conversion-specific data;
   *   mbstate_t *state - mbstate_t object where shift state will be stored;
   *
   * DESCRIPTION:
   *   Returns encoding's current shift sequence.
   */
  _VOID _EXPARM(get_state, (_VOID_PTR data,
                           mbstate_t *state));

  /*
   * set_state - set shift state.
   *
   * PARAMETERS:
   *   _VOID_PTR data   - conversion-specific data;
   *   mbstate_t *state - mbstate_t value to which shift state will be set.
   *
   * DESCRIPTION:
   *   Sets encoding's current shift state to 'state'. if 'state'
   *   object is zero-object - reset current shift state.
   *   Returns 0 if '*state' object has right format, -1 else.
   */
  int _EXPARM(set_state, (_VOID_PTR data,
                         mbstate_t *state));

  /*
   * is_stateful - is encoding stateful state.
   *
   * PARAMETERS:
   *   _VOID_PTR data   - conversion-specific data;
   *
   * DESCRIPTION:
   *   Returns 0 if encoding is stateless, else returns 1.
   */
  int _EXPARM(is_stateful, (_VOID_PTR data));
  
  /*
   * convert_to_ucs - convert character to UCS.
   *
   * PARAMETERS:
   *   _VOID_PTR data               - CES converter-specific data;
   *   _CONST unsigned char **inbuf - buffer with input character byte sequence;
   *   size_t *inbytesleft          - output buffer bytes count.
   *
   * DESCRIPTION:
   *   Converts input characters into UCS encoding. 'inbuf' is
   *   incremented accordingly. 'bytesleft' is decremented accordingly. Should
   *   be provided by correspondent CES module.
   *
   * RETURN:
   *   Returns resulting UCS code if success. If input character is invalid,
   *   returns ICONV_CES_INVALID_CHARACTER. If invalid or incomplete bytes
   *   sequence was met, returns ICONV_CES_BAD_SEQUENCE.
   */
  ucs4_t _EXPARM(convert_to_ucs, (_VOID_PTR data,
                                 _CONST unsigned char **inbuf,
                                 size_t *inbytesleft));
} iconv_to_ucs_ces_handlers_t;


/*
 * iconv_from_ucs_ces_handlers_t - "from UCS" CES converter handlers.
 *
 * Structure contains function pointers which should be provided by
 * "from_ucs" CES converter.
 *
 * ============================================================================
 */
typedef struct
{
  /* Same as in iconv_to_ucs_ces_handlers_t */
  _VOID_PTR _EXPARM(init, (struct _reent *rptr,
                          _CONST char *encoding));

  /* Same as in iconv_to_ucs_ces_handlers_t */
  size_t _EXPARM(close, (struct _reent *rptr,
                        _VOID_PTR data));

  /* Same as in iconv_to_ucs_ces_handlers_t */
  int _EXPARM(get_mb_cur_max, (_VOID_PTR data));

  /* Same as in iconv_to_ucs_ces_handlers_t */
  _VOID _EXPARM(get_state, (_VOID_PTR data,
                           mbstate_t *state));

  /* Same as in iconv_to_ucs_ces_handlers_t */
  int _EXPARM(set_state, (_VOID_PTR data,
                         mbstate_t *state));

  /* Same as in iconv_to_ucs_ces_handlers_t */
  int _EXPARM(is_stateful, (_VOID_PTR data));
  
  /*
   * convert_from_ucs - convert UCS character to destination encoding.
   *
   * PARAMETERS:
   *   _VOID_PTR data         - CES converter-specific data;
   *   ucs4_t in              - input UCS-4 character;
   *   unsigned char **outbuf - output buffer for the result;
   *   size_t *outbytesleft   - output buffer bytes count.
   *
   * DESCRIPTION:
   *   Converts input UCS characters to destination encoding and stores result
   *   in 'outbuf' if there is sufficient free space present. 'outbuf' is
   *   incremented accordingly. 'outbytesleft' is decremented accordingly. Should
   *   be provided by correspondent CES module.
   *   Output buffer always has at least 1 byte.
   *
   * RETURN:
   *   Returns number of bytes that was written into output buffer if success.
   *   If there is no enough space in output buffer, returns ICONV_CES_NOSPACE.
   *   If there is no corresponding character in destination encoding, returns
   *   ICONV_CES_INVALID_CHARACTER.
   */
  size_t _EXPARM(convert_from_ucs, (_VOID_PTR data,
                                   ucs4_t in,
                                   unsigned char **outbuf,
                                   size_t *outbytesleft));
} iconv_from_ucs_ces_handlers_t;


/*
 * iconv_to_ucs_ces_desc_t - "to UCS" CES converter definition structure for
 * usage in iconv_ucs_conversion_t conversion description structure.
 *
 * ============================================================================
 */
typedef struct
{
  /* CES converter handlers */
  _CONST iconv_to_ucs_ces_handlers_t *handlers;
  
  /* "to_ucs" CES converter-specific data. */
  _VOID_PTR data;
} iconv_to_ucs_ces_desc_t;


/*
 * iconv_from_ucs_ces_desc_t - "from UCS" CES converter definition structure for
 * usage in iconv_ucs_conversion_t conversion description structure.
 *
 * ============================================================================
 */
typedef struct
{
  /* CES converter handlers */
  _CONST iconv_from_ucs_ces_handlers_t *handlers;
  
  /* "from_ucs" CES converter-specific data. */
  _VOID_PTR data;
} iconv_from_ucs_ces_desc_t;


/*
 * iconv_ucs_conversion_t - UCS-based conversion definition structure.
 *
 * Defines special type of conversion where every character is first
 * converted into UCS-4 (UCS-2 for table-driven), and after this the
 * resulting UCS character is converted to destination encoding. 
 * UCS-based conversion is composed of two *converters*, defined by 
 * iconv_ces_t structure. The iconv_ucs_conversion_t object is referred
 * from iconv_conversion_t object using 'data' field.
 *
 * Structure contains two objects - 'to_ucs' and 'from_ucs' which define
 * "source encoding to UCS" and "UCS to destination encoding" converters.
 *
 * ============================================================================
 */
typedef struct
{
  /* Source encoding -> CES converter. */
  iconv_to_ucs_ces_desc_t to_ucs;

  /* UCS -> destination encoding CES converter. */
  iconv_from_ucs_ces_desc_t from_ucs;
} iconv_ucs_conversion_t;


/*
 * iconv_to_ucs_ces_t - defines "to UCS" CES converter.
 *
 * ============================================================================
 */
typedef struct
{
  /* 
   * An array of encodings names, supported by CES converter.
   * The end of array should be marked by NULL pointer.
   */
  _CONST char **names;

  /* CES converter description structure */
  _CONST iconv_to_ucs_ces_handlers_t *handlers;
} iconv_to_ucs_ces_t;


/*
 * iconv_from_ucs_ces_t - defines "from UCS" CES converter.
 *
 * ============================================================================
 */
typedef struct
{
  /* 
   * An array of encodings names, supported by CES converter.
   * The end of array should be marked by NULL pointer.
   */
  _CONST char **names;

  /* CES converter description structure */
  _CONST iconv_from_ucs_ces_handlers_t *handlers;
} iconv_from_ucs_ces_t;
 

/* List of "to UCS" linked-in CES converters. */
extern _CONST iconv_to_ucs_ces_t
_iconv_to_ucs_ces[];

/* List of "from UCS" linked-in CES converters. */
extern _CONST iconv_from_ucs_ces_t
_iconv_from_ucs_ces[];

#endif /* !__ICONV_UCS_CONVERSION_H__ */


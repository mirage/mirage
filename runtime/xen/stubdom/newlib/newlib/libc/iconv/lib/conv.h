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
#ifndef __ICONV_CONVERSION_H__
#define __ICONV_CONVERSION_H__

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include <wchar.h>

/* Bits for 'flags' parameter of 'convert' call */
#define ICONV_DONT_SAVE_BIT 1
#define ICONV_FAIL_BIT      2

/*
 * iconv_conversion_handlers_t - keeps iconv conversion handlers.
 *
 * Keeps 6 interface function handlers:
 * open(), close(), convert(), get_mb_cur_max(), get_state(), set_state(),
 * get_mb_cur_max() and is_stateful(). Last 5 interface functions are needed to
 * support locale subsystem.
 *
 * ============================================================================
 */
typedef struct
{
  /*
   * open - open and initialize conversion.
   *
   * PARAMETERS:
   *   struct _reent *rptr - reent structure of current thread/process;
   *   _CONST char *to     - output encoding's normalized name;
   *   _CONST char *from   - input encoding's normalized name.
   * 
   * DESCRIPTION:
   *   This function is called from iconv_open() to open conversion. Returns
   *   a pointer to conversion-specific data.
   *
   * RETURN:
   *   Pointer to conversion-specific data if success. In case of error
   *   returns NULL and sets current thread's/process's errno.
   */
  _VOID_PTR _EXPARM(open, (struct _reent *rptr,
                          _CONST char *to,
                          _CONST char *from));
  
  /*
   * close - close conversion.
   *
   * PARAMETRS:
   *   struct _reent *rptr - reent structure of current thread/process;
   *   _VOID_PTR data      - conversion-specific data.
   *
   * DESCRIPTION:
   *   This function is called from iconv_close() to close conversion.
   *
   * RETURN:
   *   When successful, returns (size_t)0. In case of error, sets current
   *   thread's/process's errno and returns (size_t)-1 (same as iconv_open()).
   */
  size_t _EXPARM(close, (struct _reent *rptr,
                        _VOID_PTR data));
  
  /* convert - perform encoding conversion.
   *
   * PARAMETERS:
   *   struct _reent *rptr - reent structure of current thread/process.
   *   _VOID_PTR data      - conversion-specific data;
   *   _CONST unsigned char **inbuf - input data buffer;
   *   size_t *inbytesleft          - input buffer's length;
   *   unsigned char **outbuf       - output data buffer;
   *   size_t *outbytesleft         - output buffer free space;
   *   int flags                    - conversion options.
   *
   * DESCRIPTION:
   *   This function is called from iconv() to perform conversion and, if 'flags'
   *   is 0, behaves similarly to iconv(). 'inbuf', 'inbytesleft', 'outbuf' and
   *   'outbytesleft' are same as in case of iconv() function.
   *
   *   When flags & 1 isn't 0, 'outbuf' value is ignored and result isn't saved.
   *   Another conversion aspects aren't changed.
   *
   *   When flags & 2 isn't 0, function changes it's behavior in situations,
   *   when there is no character in "to" encoding that corresponds to valid
   *   character from "from" encoding. iconv() specification stands to perform
   *   implimentation-spacific default conversion. If flag & 2 isn't 0,
   *   function generates error.
   *
   * RETURN:
   *   Returns the number of characters converted in a non-reversible way.
   *   Reversible conversions are not counted. In case of error, sets current
   *   thread's/process's errno and returns (size_t)-1 (same as iconv()).
   */
  size_t _EXPARM(convert, (struct _reent *rptr,
                           _VOID_PTR data,
                           _CONST unsigned char **inbuf,
                           size_t *inbytesleft,
                           unsigned char **outbuf,
                           size_t *outbytesleft,
                           int flags));
  
  /*
   * get_state - get current shift state.
   *
   * PARAMETERS:
   *   _VOID_PTR data   - conversion-specific data;
   *   mbstate_t *state - mbstate_t object where shift state will be written;
   *   int direction      - 0-"from", 1-"to".
   *
   * DESCRIPTION:
   *   Returns encoding's current shift sequence.
   *   If 'direction' is 0, "from" encoding is tested, else
   *   "to" encoding is tested.
   */
  _VOID _EXPARM(get_state, (_VOID_PTR data,
                           mbstate_t *state,
                           int direction));

  /*
   * set_state - set shift state.
   *
   * PARAMETERS:
   *   _VOID_PTR data   - conversion-specific data;
   *   mbstate_t *state - mbstate_t object to which shift state will be set.
   *   int direction     - 0-"from", 1-"to".
   *
   * DESCRIPTION:
   *   Sets encoding's current shift state to 'state'. if 'state'
   *   object is zero-object - reset current shift state.
   *   If 'direction' is 0, "from" encoding is set, else
   *   "to" encoding is set.
   *   Returns 0 if '*state' object has right format, -1 else.
   */
  int _EXPARM(set_state, (_VOID_PTR data,
                         mbstate_t *state,
                         int direction));
  
  /*
   * get_mb_cur_max - get maximum character length in bytes.
   *
   * PARAMETERS:
   *   _VOID_PTR data     - conversion-specific data;
   *   int direction      - 0-"from", 1-"to".
   *
   * DESCRIPTION:
   *   Returns encoding's maximum character length.
   *   If 'direction' is 0, "from" encoding is tested, else
   *   "to" encoding is tested.
   */
  int _EXPARM(get_mb_cur_max, (_VOID_PTR data,
                              int direction));
  
  /*
   * is_stateful - is encoding stateful or stateless.
   *
   * PARAMETERS:
   *   _VOID_PTR data - conversion-specific data;
   *   int direction  - 0-"from", 1-"to".
   *
   * DESCRIPTION:
   *   Returns 0 if encoding is stateless and 1 if stateful.
   *   If 'direction' is 0, "from" encoding is tested, else
   *   "to" encoding is tested.
   */
  int _EXPARM(is_stateful, (_VOID_PTR data,
                           int direction));
  
} iconv_conversion_handlers_t;


/*
 * iconv_conversion_t - iconv conversion definition structure.
 *
 * ============================================================================
 */
typedef struct
{
  /* Iconv conversion handlers. */
  _CONST iconv_conversion_handlers_t *handlers;
  
  /*
   * Conversion-specific data (e.g., points to iconv_ucs_conversion_t
   * object if UCS-based conversion is used).
   */
  _VOID_PTR data;
} iconv_conversion_t;


/* UCS-based conversion handlers */
extern _CONST iconv_conversion_handlers_t
_iconv_ucs_conversion_handlers;

/* Null conversion handlers */
extern _CONST iconv_conversion_handlers_t
_iconv_null_conversion_handlers;

#endif /* !__ICONV_CONVERSION_H__ */


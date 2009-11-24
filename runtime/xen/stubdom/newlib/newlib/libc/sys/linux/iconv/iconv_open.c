/* Get descriptor for character set conversion.
   Copyright (C) 1997, 1998, 1999, 2000, 2001 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Ulrich Drepper <drepper@cygnus.com>, 1997.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

#include <errno.h>
#include <iconv.h>
#include <stdlib.h>
#include <string.h>

#include <gconv_int.h>
#include "gconv_charset.h"


iconv_t
iconv_open (const char *tocode, const char *fromcode)
{
  char *tocode_conv;
  char *fromcode_conv;
  size_t tocode_len;
  size_t fromcode_len;
  __gconv_t cd;
  int res;

  /* Normalize the name.  We remove all characters beside alpha-numeric,
     '_', '-', '/', and '.'.  */
  tocode_len = strlen (tocode);
  tocode_conv = alloca (tocode_len + 3);
  strip (tocode_conv, tocode);
  tocode = tocode_conv[2] == '\0' ? upstr (tocode_conv, tocode) : tocode_conv;

  fromcode_len = strlen (fromcode);
  fromcode_conv = alloca (fromcode_len + 3);
  strip (fromcode_conv, fromcode);
  fromcode = (fromcode_conv[2] == '\0'
	      ? upstr (fromcode_conv, fromcode) : fromcode_conv);

  res = __gconv_open (tocode, fromcode, &cd, 0);

  if (__builtin_expect (res, __GCONV_OK) != __GCONV_OK)
    {
      /* We must set the error number according to the specs.  */
      if (res == __GCONV_NOCONV || res == __GCONV_NODB)
	__set_errno (EINVAL);

      return (iconv_t) -1;
    }

  return (iconv_t) cd;
}

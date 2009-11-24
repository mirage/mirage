/* Convert characters in input buffer using conversion descriptor to
   output buffer.
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

#include <assert.h>
#include <gconv_int.h>
#include <sys/param.h>
#include <dlfcn.h>
#include <stddef.h>

int
internal_function
__gconv (__gconv_t cd, const unsigned char **inbuf,
	 const unsigned char *inbufend, unsigned char **outbuf,
	 unsigned char *outbufend, size_t *irreversible)
{
  size_t last_step;
  int result;

  if (cd == (__gconv_t) -1L)
    return __GCONV_ILLEGAL_DESCRIPTOR;

  last_step = cd->__nsteps - 1;

  assert (irreversible != NULL);
  *irreversible = 0;

  cd->__data[last_step].__outbuf = outbuf != NULL ? *outbuf : NULL;
  cd->__data[last_step].__outbufend = outbufend;

  if (inbuf == NULL || *inbuf == NULL)
    /* We just flush.  */
    result = cd->__steps->__fct (cd->__steps, cd->__data, NULL, NULL, NULL,
                                 irreversible,
                                 cd->__data[last_step].__outbuf == NULL ? 2 : 1, 0);
  else
    {
      const unsigned char *last_start;

      assert (outbuf != NULL && *outbuf != NULL);

      do
	{
	  last_start = *inbuf;
	  result = cd->__steps->__fct (cd->__steps, cd->__data, inbuf, inbufend,
				 NULL, irreversible, 0, 0);
	}
      while (result == __GCONV_EMPTY_INPUT && last_start != *inbuf
	     && *inbuf + cd->__steps->__min_needed_from <= inbufend);
    }

  if (outbuf != NULL && *outbuf != NULL)
    *outbuf = cd->__data[last_step].__outbuf;

  return result;
}

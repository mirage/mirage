/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <errno.h>
#include <sys/types.h>
#include <string.h>
#include <stdlib.h>

error_t
_DEFUN (argz_append, (argz, argz_len, buf, buf_len),
       char **argz _AND
       size_t *argz_len _AND
       const char *buf _AND
       size_t buf_len)
{
  if (buf_len)
    {
      size_t last = *argz_len;

      *argz_len += buf_len;

      if(!(*argz = (char *)realloc(*argz, *argz_len)))
	return ENOMEM;

      memcpy(*argz + last, buf, buf_len);
    }
  return 0;
}

/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <errno.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <argz.h>

error_t
_DEFUN (argz_add_sep, (argz, argz_len, str, sep),
       char **argz _AND
       size_t *argz_len _AND
       const char *str _AND
       int sep)
{
  char *str_argz = 0;
  size_t str_argz_len = 0;
  size_t last = *argz_len;

  argz_create_sep (str, sep, &str_argz, &str_argz_len);

  if (str_argz_len)
    {
      *argz_len += str_argz_len;

      if(!(*argz = (char *)realloc(*argz, *argz_len)))
	return ENOMEM;

      memcpy(*argz + last, str_argz, str_argz_len);
    }
  return 0;
}

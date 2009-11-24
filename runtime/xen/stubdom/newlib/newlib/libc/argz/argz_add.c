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
_DEFUN (argz_add, (argz, argz_len, str),
       char **argz _AND
       size_t *argz_len _AND
       const char *str)
{
  int len_to_add = 0;
  size_t last = *argz_len;

  if (str == NULL)
    return 0;

  len_to_add = strlen(str) + 1;
  *argz_len += len_to_add;

  if(!(*argz = (char *)realloc(*argz, *argz_len)))
    return ENOMEM;

  memcpy(*argz + last, str, len_to_add);
  return 0;
}

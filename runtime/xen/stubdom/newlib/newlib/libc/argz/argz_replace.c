/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <errno.h>
#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
#include <argz.h>

#include "buf_findstr.h"

error_t
_DEFUN (argz_replace, (argz, argz_len, str, with, replace_count),
       char **argz _AND
       size_t *argz_len _AND
       const char *str _AND
       const char *with _AND
       unsigned *replace_count)
{
  const int str_len = strlen(str);
  const int with_len = strlen(with);
  const int len_diff = with_len - str_len;

  char *buf_iter = *argz;
  size_t buf_len = *argz_len;
  char *last_iter = NULL;
  char *new_argz = NULL;
  size_t new_argz_len = 0;
  char *new_argz_iter = NULL;

  *replace_count = 0;
  new_argz_len = *argz_len;

  while(buf_len)
    {
      if(_buf_findstr(str, &buf_iter, &buf_len))
        {
          *replace_count += 1;
          new_argz_len += len_diff;
        }
    }

  if (*replace_count)
    {
      new_argz = (char *)malloc(new_argz_len);
      
      buf_iter = *argz;
      buf_len = *argz_len;
      last_iter = buf_iter;
      new_argz_iter = new_argz;
      
      while(buf_len)
        {
          if (_buf_findstr(str, &buf_iter, &buf_len))
            {
              /* copy everything up to, but not including str, from old argz to
                 new argz. */
              memcpy(new_argz_iter, last_iter, buf_iter - last_iter - str_len);
              new_argz_iter += (buf_iter - last_iter - str_len);
              /* copy replacement string. */
              memcpy(new_argz_iter, with, with_len);
              new_argz_iter += with_len;
              last_iter = buf_iter;
            }
        }
      /* copy everything after last occurrence of str. */
      memcpy(new_argz_iter, last_iter, *argz + *argz_len - last_iter);

      /* reallocate argz, and copy over the new value. */
      if(!(*argz = (char *)realloc(*argz, new_argz_len)))
        return ENOMEM;

      memcpy(*argz, new_argz, new_argz_len);
      *argz_len = new_argz_len;

      if (*argz_len == 0)
        {
          free(*argz);
          *argz = NULL;
        }
      free(new_argz);
    }

  return 0;
}

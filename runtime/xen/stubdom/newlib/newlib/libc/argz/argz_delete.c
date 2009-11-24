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
_DEFUN (argz_delete, (argz, argz_len, entry),
       char **argz _AND
       size_t *argz_len _AND
       char *entry)
{
  int len = 0;
  char *moveto = entry;

  if (entry)
    {
      len = strlen(entry) + 1;
      entry += len;
      
      memmove(moveto, entry, *argz + *argz_len - entry);

      *argz_len -= len;

      if(!(*argz = (char *)realloc(*argz, *argz_len)))
        return ENOMEM;

      if (*argz_len <= 0)
        {
          free(*argz);
          *argz = NULL;
        }
    }
  return 0;
}

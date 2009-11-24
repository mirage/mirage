/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <errno.h>
#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
#include <envz.h>

#include "buf_findstr.h"

char *
_DEFUN (envz_get, (envz, envz_len, name),
       const char *envz _AND 
       size_t envz_len _AND
       const char *name)
{
  char *buf_ptr = (char *)envz;
  size_t buf_len = envz_len;

  while(buf_len)
    {
      if (_buf_findstr(name, &buf_ptr, &buf_len))
        {
          if (*buf_ptr == '=')
            {
              buf_ptr++;
              return (char *)buf_ptr;
            }
          else
            {
              if (*buf_ptr == '\0')
                /* NULL entry. */
                return NULL;
            }
        }
    }
  /* No matching entries found. */
  return NULL;
}

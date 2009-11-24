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
#include <envz.h>

void
_DEFUN (envz_strip, (envz, envz_len),
       char **envz _AND
       size_t *envz_len)
{
  char *entry = 0;
  int len = 0;
  int null_found = 0;

  while((entry = argz_next(*envz, *envz_len, entry)))
    {
      if(!strchr(entry, '='))
        {
          null_found = 1;
          len = strlen(entry) + 1;
          /* Make sure this is not the last entry in envz. If it is, it
           will be chopped off by the realloc anyway.*/
          if(*envz + *envz_len != entry + len - 1)
            {
              memmove(entry, entry + len, *envz + *envz_len - entry - len);
            }
          *envz_len -= len;
        }
    }
  if(null_found)
    {
      *envz = (char *)realloc(*envz, *envz_len);
    }
}

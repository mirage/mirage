/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <_ansi.h>
#include <sys/types.h>

size_t
_DEFUN (argz_count, (argz, argz_len), 
       const char *argz _AND
       size_t argz_len)
{
  int i;
  size_t count = 0;

  for (i = 0; i < argz_len; i++)
    {
      if (argz[i] == '\0')
        count++;
    }
  return count;
}

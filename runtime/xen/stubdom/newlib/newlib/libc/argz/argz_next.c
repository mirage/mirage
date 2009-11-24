/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <errno.h>
#include <sys/types.h>
#include <string.h>
#include <stdlib.h>

char *
_DEFUN (argz_next, (argz, argz_len, entry),
       char *argz _AND
       size_t argz_len _AND
       const char *entry)
{
  if (entry)
    {
      while(*entry != '\0')
        entry++;
      entry++;

      if (entry >= argz + argz_len)
        return NULL;
      else
        return (char *) entry;
    }
  else
    {
      if (argz_len > 0)
        return (char *) argz;
      else
        return NULL;
    }
}

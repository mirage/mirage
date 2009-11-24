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
_DEFUN (envz_remove, (envz, envz_len, name),
       char **envz _AND
       size_t *envz_len _AND
       const char *name)
{
  char *entry = NULL;
  int len = 0;
  entry = envz_entry (*envz, *envz_len, name);

  if (entry)
    {
      len = strlen(entry) + 1;

      /* Not the last entry. */
      if (*envz + *envz_len != entry + len - 1)
        {
          memmove(entry, entry + len, *envz + *envz_len - entry - len);
        }

      *envz = (char *)realloc(*envz, *envz_len - len);
      *envz_len -= len;
    }
}

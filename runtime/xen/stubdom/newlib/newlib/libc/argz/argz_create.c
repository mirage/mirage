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
_DEFUN (argz_create, (argv, argz, argz_len),
       char *const argv[] _AND
       char **argz _AND
       size_t *argz_len)
{
  int argc = 0;
  int i = 0;
  int len = 0;
  char *iter;

  *argz_len = 0;

  if (*argv == NULL)
    {
      *argz = NULL;
      return 0;
    }

  while (argv[argc])
    {
      *argz_len += (strlen(argv[argc]) + 1);
      argc++;
    }

  /* There are argc strings to copy into argz. */
  if(!(*argz = (char *)malloc(*argz_len)))
    return ENOMEM;

  iter = *argz;
  for(i = 0; i < argc; i++)
    {
      len = strlen(argv[i]) + 1;
      memcpy(iter, argv[i], len);
      iter += len;
    }
  return 0;
}

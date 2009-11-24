/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <argz.h>
#include <sys/types.h>

void
_DEFUN (argz_extract, (argz, argz_len, argv),
       char *argz _AND
       size_t argz_len _AND
       char **argv)
{
  size_t i = 0;
  int j = 0;
  const size_t count = argz_count(argz, argz_len);

  if (argz_len > 1)
    for (i = argz_len - 2; i > 0; i--)
      {
	if (argz[i] == '\0')
	  {
	    j++;
	    argv[count - j] = &argz[i + 1];
	  }
      }
  argv[0] = &argz[0];
  argv[count] = NULL;
}

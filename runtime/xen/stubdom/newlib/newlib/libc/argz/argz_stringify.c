/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <_ansi.h>
#include <sys/types.h>

void
_DEFUN (argz_stringify, (argz, argz_len, sep),
       char *argz _AND
       size_t argz_len _AND
       int sep)
{
  size_t i;

  /* len includes trailing \0, which we don't want to replace. */
  if (argz_len > 1)
    for (i = 0; i < argz_len - 1; i++)
      {
	if (argz[i] == '\0')
	  argz[i] = sep;
      }
}

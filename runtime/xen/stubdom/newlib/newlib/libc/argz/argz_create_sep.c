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
_DEFUN (argz_create_sep, (string, sep, argz, argz_len),
       const char *string _AND
       int sep _AND
       char **argz _AND
       size_t *argz_len)
{
  int len = 0;
  int i = 0;
  int num_strings = 0;
  char delim[2];
  char *running = 0;
  char *old_running = 0;
  char *token = 0;
  char *iter = 0;

  *argz_len = 0;

  if (!string || string[0] == '\0')
    {
      *argz= NULL;
      return 0;
    }

  delim[0] = sep;
  delim[1] = '\0';

  running = strdup(string);
  old_running = running;

  while ((token = strsep(&running, delim)))
    {
      len = strlen(token);
      *argz_len += (len + 1);
      num_strings++;
    }

  if(!(*argz = (char *)malloc(*argz_len)))
    return ENOMEM;

  free(old_running);

  running = strdup(string);
  old_running = running;

  iter = *argz;
  for (i = 0; i < num_strings; i++)
    {
      token = strsep(&running, delim);
      len = strlen(token) + 1;
      memcpy(iter, token, len);
      iter += len;
    }

  free(old_running);
  return 0;
}

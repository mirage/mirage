/* Copyright (C) 2002 by  Red Hat, Incorporated. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

#include <sys/param.h>
#include <sys/stat.h>

#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <glob.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <wordexp.h>

void
wordfree(wordexp_t *pwordexp)
{
  int i;

  if (pwordexp == NULL)
    return;

  if (pwordexp->we_wordv == NULL)
    return;

  for(i = 0; i < pwordexp->we_wordc; i++)
    free(pwordexp->we_wordv[i]);

  free(pwordexp->we_wordv);
  pwordexp->we_wordv = NULL;
}

/* This file may have been modified by DJ Delorie (Jan 1991).  If so,
** these modifications are Copyright (C) 1991 DJ Delorie.
*/

/*-
 * Copyright (c) 1988 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that: (1) source distributions retain this entire copyright
 * notice and comment, and (2) distributions including binaries display
 * the following acknowledgement:  ``This product includes software
 * developed by the University of California, Berkeley and its contributors''
 * in the documentation or other materials provided with the distribution
 * and in all advertising materials mentioning features or use of this
 * software. Neither the name of the University nor the names of its
 * contributors may be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

#include <reent.h>
#include <stdlib.h>
#include <string.h>

#include "envlock.h"

/* _putenv_r - reentrant version of putenv that either adds
               or replaces the environment variable "name"
               with "value" which is specified by str as "name=value". */
int
_DEFUN (_putenv_r, (reent_ptr, str),
	struct _reent *reent_ptr _AND
	char   *str)
{
  register char *p, *equal;
  int rval;

  p = _strdup_r (reent_ptr, str);

  if (!p)
    return 1;

  if (!(equal = index (p, '=')))
    {
      (void) _free_r (reent_ptr, p);
      return 1;
    }

  *equal = '\0';
  rval = _setenv_r (reent_ptr, p, equal + 1, 1);
  (void) _free_r (reent_ptr, p);

  return rval;
}

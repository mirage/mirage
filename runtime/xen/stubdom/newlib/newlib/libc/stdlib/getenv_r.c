/*
FUNCTION
<<_getenv_r>>---look up environment variable

INDEX
	_getenv_r
INDEX
	environ

ANSI_SYNOPSIS
	#include <stdlib.h>
	char *_getenv_r(struct _reent *<[reent_ptr]>, const char *<[name]>);

TRAD_SYNOPSIS
	#include <stdlib.h>
	char *_getenv_r(<[reent_ptr]>, <[name]>)
	struct _reent *<[reent_ptr]>;
	char *<[name]>;

DESCRIPTION
<<_getenv_r>> searches the list of environment variable names and values
(using the global pointer ``<<char **environ>>'') for a variable whose
name matches the string at <[name]>.  If a variable name matches,
<<_getenv_r>> returns a pointer to the associated value.

RETURNS
A pointer to the (string) value of the environment variable, or
<<NULL>> if there is no such environment variable.

PORTABILITY
<<_getenv_r>> is not ANSI; the rules for properly forming names of environment
variables vary from one system to another.

<<_getenv_r>> requires a global pointer <<environ>>.
*/

/* This file may have been modified by DJ Delorie (Jan 1991).  If so,
** these modifications are Copyright (C) 1991 DJ Delorie.
*/

/*
 * Copyright (c) 1987 Regents of the University of California.
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

#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include "envlock.h"

extern char **environ;

/* Only deal with a pointer to environ, to work around subtle bugs with shared
   libraries and/or small data systems where the user declares his own
   'environ'.  */
static char ***p_environ = &environ;

/*
 * _findenv --
 *	Returns pointer to value associated with name, if any, else NULL.
 *	Sets offset to be the offset of the name/value combination in the
 *	environmental array, for use by setenv(3) and unsetenv(3).
 *	Explicitly removes '=' in argument name.
 *
 *	This routine *should* be a static; don't use it.
 */

char *
_DEFUN (_findenv_r, (reent_ptr, name, offset),
        struct _reent *reent_ptr   _AND
	register _CONST char *name _AND
	int *offset)
{
  register int len;
  register char **p;
  _CONST char *c;

  ENV_LOCK;

  /* In some embedded systems, this does not get set.  This protects
     newlib from dereferencing a bad pointer.  */
  if (!*p_environ)
    {
      ENV_UNLOCK;
      return NULL;
    }

  c = name;
  len = 0;
  while (*c && *c != '=')
    {
      c++;
      len++;
    }

  for (p = *p_environ; *p; ++p)
    if (!strncmp (*p, name, len))
      if (*(c = *p + len) == '=')
	{
	  *offset = p - *p_environ;
          ENV_UNLOCK;
	  return (char *) (++c);
	}
  ENV_UNLOCK;
  return NULL;
}

/*
 * _getenv_r --
 *	Returns ptr to value associated with name, if any, else NULL.
 */

char *
_DEFUN (_getenv_r, (reent_ptr, name),
        struct _reent *reent_ptr _AND
	_CONST char *name)
{
  int offset;
  char *_findenv_r ();

  return _findenv_r (reent_ptr, name, &offset);
}

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

#include <reent.h>

#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "envlock.h"

extern char **environ;

/* Only deal with a pointer to environ, to work around subtle bugs with shared
   libraries and/or small data systems where the user declares his own
   'environ'.  */
static char ***p_environ = &environ;

/* _findenv_r is defined in getenv_r.c.  */
extern char *_findenv_r _PARAMS ((struct _reent *, const char *, int *));

/*
 * _setenv_r --
 *	Set the value of the environmental variable "name" to be
 *	"value".  If rewrite is set, replace any current value.
 */

int
_DEFUN (_setenv_r, (reent_ptr, name, value, rewrite),
        struct _reent *reent_ptr _AND
	_CONST char *name _AND
	_CONST char *value _AND
	int rewrite)
{
  static int alloced;		/* if allocated space before */
  register char *C;
  int l_value, offset;

  ENV_LOCK;

  if (*value == '=')		/* no `=' in value */
    ++value;
  l_value = strlen (value);
  if ((C = _findenv_r (reent_ptr, name, &offset)))
    {				/* find if already exists */
      if (!rewrite)
        {
          ENV_UNLOCK;
	  return 0;
        }
      if (strlen (C) >= l_value)
	{			/* old larger; copy over */
	  while ((*C++ = *value++) != 0);
          ENV_UNLOCK;
	  /* if we are changing the TZ environment variable, update timezone info */
	  if (strcmp (name, "TZ") == 0)
	    tzset ();
	  return 0;
	}
    }
  else
    {				/* create new slot */
      register int cnt;
      register char **P;

      for (P = *p_environ, cnt = 0; *P; ++P, ++cnt);
      if (alloced)
	{			/* just increase size */
	  *p_environ = (char **) _realloc_r (reent_ptr, (char *) environ,
					     (size_t) (sizeof (char *) * (cnt + 2)));
	  if (!*p_environ)
            {
              ENV_UNLOCK;
	      return -1;
            }
	}
      else
	{			/* get new space */
	  alloced = 1;		/* copy old entries into it */
	  P = (char **) _malloc_r (reent_ptr, (size_t) (sizeof (char *) * (cnt + 2)));
	  if (!P)
            {
              ENV_UNLOCK;
	      return (-1);
            }
	  bcopy ((char *) *p_environ, (char *) P, cnt * sizeof (char *));
	  *p_environ = P;
	}
      (*p_environ)[cnt + 1] = NULL;
      offset = cnt;
    }
  for (C = (char *) name; *C && *C != '='; ++C);	/* no `=' in name */
  if (!((*p_environ)[offset] =	/* name + `=' + value */
	_malloc_r (reent_ptr, (size_t) ((int) (C - name) + l_value + 2))))
    {
      ENV_UNLOCK;
      return -1;
    }
  for (C = (*p_environ)[offset]; (*C = *name++) && *C != '='; ++C);
  for (*C++ = '='; (*C++ = *value++) != 0;);

  ENV_UNLOCK;

  /* if we are setting the TZ environment variable, update timezone info */
  if (strncmp ((*p_environ)[offset], "TZ=", 3) == 0)
    tzset ();

  return 0;
}

/*
 * _unsetenv_r(name) --
 *	Delete environmental variable "name".
 */
void
_DEFUN (_unsetenv_r, (reent_ptr, name),
        struct _reent *reent_ptr _AND
        _CONST char *name)
{
  register char **P;
  int offset;

  ENV_LOCK;

  while (_findenv_r (reent_ptr, name, &offset))	/* if set multiple times */
    for (P = &(*p_environ)[offset];; ++P)
      if (!(*P = *(P + 1)))
	break;

  ENV_UNLOCK;
}

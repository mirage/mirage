/* BSD strsep function */

/* Copyright 2002, Red Hat Inc. */

/* undef STRICT_ANSI so that strsep prototype will be defined */
#undef  __STRICT_ANSI__
#include <string.h>
#include <_ansi.h>
#include <reent.h>

extern char *__strtok_r (char *, const char *, char **, int);

char *
_DEFUN (strsep, (source_ptr, delim),
	register char **source_ptr _AND
	register const char *delim)
{
	return __strtok_r (*source_ptr, delim, source_ptr, 0);
}

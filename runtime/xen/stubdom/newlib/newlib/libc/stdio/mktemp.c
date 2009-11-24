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
/* This is file MKTEMP.C */
/* This file may have been modified by DJ Delorie (Jan 1991).  If so,
** these modifications are Copyright (C) 1991 DJ Delorie.
*/

/*
FUNCTION
<<mktemp>>, <<mkstemp>>---generate unused file name

INDEX
	mktemp
INDEX
	mkstemp
INDEX
	_mktemp_r
INDEX
	_mkstemp_r

ANSI_SYNOPSIS
	#include <stdio.h>
	char *mktemp(char *<[path]>);
	int mkstemp(char *<[path]>);

	char *_mktemp_r(struct _reent *<[reent]>, char *<[path]>);
	int *_mkstemp_r(struct _reent *<[reent]>, char *<[path]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	char *mktemp(<[path]>)
	char *<[path]>;

	int mkstemp(<[path]>)
	char *<[path]>;

	char *_mktemp_r(<[reent]>, <[path]>)
	struct _reent *<[reent]>;
	char *<[path]>;

	int _mkstemp_r(<[reent]>, <[path]>)
	struct _reent *<[reent]>;
	char *<[path]>;

DESCRIPTION
<<mktemp>> and <<mkstemp>> attempt to generate a file name that is not
yet in use for any existing file.  <<mkstemp>> creates the file and
opens it for reading and writing; <<mktemp>> simply generates the file name.

You supply a simple pattern for the generated file name, as the string
at <[path]>.  The pattern should be a valid filename (including path
information if you wish) ending with some number of `<<X>>'
characters.  The generated filename will match the leading part of the
name you supply, with the trailing `<<X>>' characters replaced by some
combination of digits and letters.

The alternate functions <<_mktemp_r>> and <<_mkstemp_r>> are reentrant
versions.  The extra argument <[reent]> is a pointer to a reentrancy
structure.

RETURNS
<<mktemp>> returns the pointer <[path]> to the modified string
representing an unused filename, unless it could not generate one, or
the pattern you provided is not suitable for a filename; in that case,
it returns <<NULL>>.

<<mkstemp>> returns a file descriptor to the newly created file,
unless it could not generate an unused filename, or the pattern you
provided is not suitable for a filename; in that case, it returns
<<-1>>.

PORTABILITY
ANSI C does not require either <<mktemp>> or <<mkstemp>>; the System
V Interface Definition requires <<mktemp>> as of Issue 2.

Supporting OS subroutines required: <<getpid>>, <<open>>, <<stat>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <errno.h>
#include <stdio.h>
#include <ctype.h>

static int
_DEFUN(_gettemp, (ptr, path, doopen),
       struct _reent *ptr _AND
       char *path         _AND
       register int *doopen)
{
  register char *start, *trv;
#ifdef __USE_INTERNAL_STAT64
  struct stat64 sbuf;
#else
  struct stat sbuf;
#endif
  unsigned int pid;

  pid = _getpid_r (ptr);
  for (trv = path; *trv; ++trv)		/* extra X's get set to 0's */
    continue;
  while (*--trv == 'X')
    {
      *trv = (pid % 10) + '0';
      pid /= 10;
    }

  /*
   * Check the target directory; if you have six X's and it
   * doesn't exist this runs for a *very* long time.
   */

  for (start = trv + 1;; --trv)
    {
      if (trv <= path)
	break;
      if (*trv == '/')
	{
	  *trv = '\0';
#ifdef __USE_INTERNAL_STAT64
	  if (_stat64_r (ptr, path, &sbuf))
#else
	  if (_stat_r (ptr, path, &sbuf))
#endif
	    return (0);
	  if (!(sbuf.st_mode & S_IFDIR))
	    {
	      ptr->_errno = ENOTDIR;
	      return (0);
	    }
	  *trv = '/';
	  break;
	}
    }

  for (;;)
    {
      if (doopen)
	{
	  if ((*doopen = _open_r (ptr, path, O_CREAT | O_EXCL | O_RDWR, 0600))
	      >= 0)
	    return 1;
#if defined(__CYGWIN__)
	  if (ptr->_errno != EEXIST && ptr->_errno != EACCES)
#else
	  if (ptr->_errno != EEXIST)
#endif
	    return 0;
	}
#ifdef __USE_INTERNAL_STAT64
      else if (_stat64_r (ptr, path, &sbuf))
#else
      else if (_stat_r (ptr, path, &sbuf))
#endif
	return (ptr->_errno == ENOENT ? 1 : 0);

      /* tricky little algorithm for backward compatibility */
      for (trv = start;;)
	{
	  if (!*trv)
	    return 0;
	  if (*trv == 'z')
	    *trv++ = 'a';
	  else
	    {
	      if (isdigit (*trv))
		*trv = 'a';
	      else
		++ * trv;
	      break;
	    }
	}
    }
  /*NOTREACHED*/
}

int
_DEFUN(_mkstemp_r, (ptr, path),
       struct _reent *ptr _AND
       char *path)
{
  int fd;

  return (_gettemp (ptr, path, &fd) ? fd : -1);
}

char *
_DEFUN(_mktemp_r, (ptr, path),
       struct _reent *ptr _AND
       char *path)
{
  return (_gettemp (ptr, path, (int *) NULL) ? path : (char *) NULL);
}

#ifndef _REENT_ONLY

int
_DEFUN(mkstemp, (path),
       char *path)
{
  int fd;

  return (_gettemp (_REENT, path, &fd) ? fd : -1);
}

char *
_DEFUN(mktemp, (path),
       char *path)
{
  return (_gettemp (_REENT, path, (int *) NULL) ? path : (char *) NULL);
}

#endif /* ! defined (_REENT_ONLY) */

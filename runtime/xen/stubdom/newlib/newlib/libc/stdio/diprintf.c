/* Copyright (C) 2005, 2007 Shaun Jackman
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

/*
FUNCTION
<<diprintf>>, <<vdiprintf>>---print to a file descriptor (integer only)

INDEX
	diprintf
INDEX
	vdiprintf

ANSI_SYNOPSIS
	#include <stdio.h>
	#include <stdarg.h>
	int diprintf(int <[fd]>, const char *<[format]>, ...);
	int vdiprintf(int <[fd]>, const char *<[format]>, va_list <[ap]>);
	int _diprintf_r(struct _reent *<[ptr]>, int <[fd]>,
			const char *<[format]>, ...);
	int _vidprintf_r(struct _reent *<[ptr]>, int <[fd]>,
			const char *<[format]>, va_list <[ap]>);

DESCRIPTION
<<diprintf>> and <<vdiprintf>> are similar to <<dprintf>> and <<vdprintf>>,
except that only integer format specifiers are processed.

The functions <<_diprintf_r>> and <<_vdiprintf_r>> are simply
reentrant versions of the functions above.

RETURNS
Similar to <<dprintf>> and <<vdprintf>>.

PORTABILITY
This set of functions is an integer-only extension, and is not portable.

Supporting OS subroutines required: <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <unistd.h>
#include <stdarg.h>

int
_DEFUN(_diprintf_r, (ptr, fd, format),
       struct _reent *ptr _AND
       int fd _AND
       const char *format _DOTS)
{
  va_list ap;
  int n;

  va_start (ap, format);
  n = _vdiprintf_r (ptr, fd, format, ap);
  va_end (ap);
  return n;
}

#ifndef _REENT_ONLY

int
_DEFUN(diprintf, (fd, format),
       int fd _AND
       const char *format _DOTS)
{
  va_list ap;
  int n;

  va_start (ap, format);
  n = _vdiprintf_r (_REENT, fd, format, ap);
  va_end (ap);
  return n;
}

#endif /* ! _REENT_ONLY */

/* Copyright 2005, 2007 Shaun Jackman
 * Permission to use, copy, modify, and distribute this software
 * is freely granted, provided that this notice is preserved.
 */

/*
FUNCTION
<<dprintf>>, <<vdprintf>>---print to a file descriptor

INDEX
	dprintf
INDEX
	vdprintf

ANSI_SYNOPSIS
	#include <stdio.h>
	#include <stdarg.h>
	int dprintf(int <[fd]>, const char *<[format]>, ...);
	int vdprintf(int <[fd]>, const char *<[format]>, va_list <[ap]>);
	int _dprintf_r(struct _reent *<[ptr]>, int <[fd]>,
			const char *<[format]>, ...);
	int _vdprintf_r(struct _reent *<[ptr]>, int <[fd]>,
			const char *<[format]>, va_list <[ap]>);

DESCRIPTION
<<dprintf>> and <<vdprintf>> allow printing a format, similarly to
<<printf>>, but write to a file descriptor instead of to a <<FILE>>
stream.

The functions <<_dprintf_r>> and <<_vdprintf_r>> are simply
reentrant versions of the functions above.

RETURNS
The return value and errors are exactly as for <<write>>, except that
<<errno>> may also be set to <<ENOMEM>> if the heap is exhausted.

PORTABILITY
This function is originally a GNU extension in glibc and is not portable.

Supporting OS subroutines required: <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <unistd.h>
#include <stdarg.h>

int
_DEFUN(_dprintf_r, (ptr, fd, format),
       struct _reent *ptr _AND
       int fd _AND
       const char *format _DOTS)
{
	va_list ap;
	int n;
	_REENT_SMALL_CHECK_INIT (ptr);
	va_start (ap, format);
	n = _vdprintf_r (ptr, fd, format, ap);
	va_end (ap);
	return n;
}

#ifndef _REENT_ONLY

int
_DEFUN(dprintf, (fd, format),
       int fd _AND
       const char *format _DOTS)
{
  va_list ap;
  int n;
  struct _reent *ptr = _REENT;

  _REENT_SMALL_CHECK_INIT (ptr);
  va_start (ap, format);
  n = _vdprintf_r (ptr, fd, format, ap);
  va_end (ap);
  return n;
}

#endif /* ! _REENT_ONLY */

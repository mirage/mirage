/*
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms are permitted
 * provided that the above copyright notice and this paragraph are
 * duplicated in all such forms and that any documentation,
 * advertising materials, and other materials related to such
 * distribution and use acknowledge that the software was developed
 * by the University of California, Berkeley.  The name of the
 * University may not be used to endorse or promote products derived
 * from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
FUNCTION
<<siscanf>>, <<fiscanf>>, <<iscanf>>---scan and format non-floating input

INDEX
	iscanf
INDEX
	fiscanf
INDEX
	siscanf

ANSI_SYNOPSIS
        #include <stdio.h>

        int iscanf(const char *<[format]> [, <[arg]>, ...]);
        int fiscanf(FILE *<[fd]>, const char *<[format]> [, <[arg]>, ...]);
        int siscanf(const char *<[str]>, const char *<[format]> 
                   [, <[arg]>, ...]);

        int _iscanf_r(struct _reent *<[ptr]>, const char *<[format]>
                   [, <[arg]>, ...]);
        int _fiscanf_r(struct _reent *<[ptr]>, FILE *<[fd]>, const char *<[format]>
                   [, <[arg]>, ...]);
        int _siscanf_r(struct _reent *<[ptr]>, const char *<[str]>,
                   const char *<[format]> [, <[arg]>, ...]);


TRAD_SYNOPSIS
	#include <stdio.h>

	int iscanf(<[format]> [, <[arg]>, ...])
	char *<[format]>;

	int fiscanf(<[fd]>, <[format]> [, <[arg]>, ...]);
	FILE *<[fd]>;
	char *<[format]>;

	int siscanf(<[str]>, <[format]> [, <[arg]>, ...]);
	char *<[str]>;
	char *<[format]>;

	int _iscanf_r(<[ptr]>, <[format]> [, <[arg]>, ...])
        struct _reent *<[ptr]>;
	char *<[format]>;

	int _fiscanf_r(<[ptr]>, <[fd]>, <[format]> [, <[arg]>, ...]);
        struct _reent *<[ptr]>;
	FILE *<[fd]>;
	char *<[format]>;

	int _siscanf_r(<[ptr]>, <[str]>, <[format]> [, <[arg]>, ...]);
        struct _reent *<[ptr]>;
	char *<[str]>;
	char *<[format]>;


DESCRIPTION
        <<iscanf>>, <<fiscanf>>, and <<siscanf>> are the same as
	<<scanf>>, <<fscanf>>, and <<sscanf>> respectively, only that
	they restrict the available formats to non-floating-point
	format specifiers.

        The routines <<_iscanf_r>>, <<_fiscanf_r>>, and <<_siscanf_r>> are reentrant
        versions of <<iscanf>>, <<fiscanf>>, and <<siscanf>> that take an additional
        first argument pointing to a reentrancy structure.

RETURNS
        <<iscanf>> returns the number of input fields successfully
        scanned, converted and stored; the return value does
        not include scanned fields which were not stored.

        If <<iscanf>> attempts to read at end-of-file, the return
        value is <<EOF>>.

        If no fields were stored, the return value is <<0>>.

PORTABILITY
<<iscanf>>, <<fiscanf>>, and <<siscanf>> are newlib extensions.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <string.h>
#ifdef _HAVE_STDC
#include <stdarg.h>
#else
#include <varargs.h>
#endif
#include "local.h"

/* | ARGSUSED */
/*SUPPRESS 590*/
static _READ_WRITE_RETURN_TYPE
_DEFUN(eofread, (ptr, cookie, buf, len),
       struct _reent *ptr _AND
       _PTR cookie _AND
       char *buf   _AND
       int len)
{
  return 0;
}

#ifndef _REENT_ONLY 

#ifdef _HAVE_STDC
int 
_DEFUN(siscanf, (str, fmt),
       _CONST char *str _AND
       _CONST char *fmt _DOTS)
#else
int 
siscanf(str, fmt, va_alist)
       _CONST char *str;
       _CONST char *fmt;
       va_dcl
#endif
{
  int ret;
  va_list ap;
  FILE f;

  f._flags = __SRD | __SSTR;
  f._bf._base = f._p = (unsigned char *) str;
  f._bf._size = f._r = strlen (str);
  f._read = eofread;
  f._ub._base = NULL;
  f._lb._base = NULL;
  f._file = -1;  /* No file. */
#ifdef _HAVE_STDC
  va_start (ap, fmt);
#else
  va_start (ap);
#endif
  ret = __svfiscanf_r (_REENT, &f, fmt, ap);
  va_end (ap);
  return ret;
}

#endif /* !_REENT_ONLY */

#ifdef _HAVE_STDC
int 
_DEFUN(_siscanf_r, (ptr, str, fmt), 
       struct _reent *ptr _AND
       _CONST char *str   _AND
       _CONST char *fmt _DOTS)
#else
int 
_siscanf_r(ptr, str, fmt, va_alist)
          struct _reent *ptr;
          _CONST char *str;
          _CONST char *fmt;
          va_dcl
#endif
{
  int ret;
  va_list ap;
  FILE f;

  f._flags = __SRD | __SSTR;
  f._bf._base = f._p = (unsigned char *) str;
  f._bf._size = f._r = strlen (str);
  f._read = eofread;
  f._ub._base = NULL;
  f._lb._base = NULL;
  f._file = -1;  /* No file. */
#ifdef _HAVE_STDC
  va_start (ap, fmt);
#else
  va_start (ap);
#endif
  ret = __svfiscanf_r (ptr, &f, fmt, ap);
  va_end (ap);
  return ret;
}

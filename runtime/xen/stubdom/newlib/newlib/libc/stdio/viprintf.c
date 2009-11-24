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
<<viprintf>>, <<vfiprintf>>, <<vsiprintf>>, <<vsniprintf>>, <<vasiprintf>>, <<vasniprintf>>---format argument list (integer only)

INDEX
	viprintf
INDEX
	vfiprintf
INDEX
	vsiprintf
INDEX
	vsniprintf
INDEX
	vasiprintf
INDEX
	vasniprintf

ANSI_SYNOPSIS
	#include <stdio.h>
	#include <stdarg.h>
	int viprintf(const char *<[fmt]>, va_list <[list]>);
	int vfiprintf(FILE *<[fp]>, const char *<[fmt]>, va_list <[list]>);
	int vsiprintf(char *<[str]>, const char *<[fmt]>, va_list <[list]>);
	int vsniprintf(char *<[str]>, size_t <[size]>, const char *<[fmt]>,
                       va_list <[list]>);
	int vasiprintf(char **<[strp]>, const char *<[fmt]>, va_list <[list]>);
	char *vasniprintf(char *<[str]>, size_t *<[size]>, const char *<[fmt]>,
                          va_list <[list]>);

	int _viprintf_r(struct _reent *<[reent]>, const char *<[fmt]>,
                        va_list <[list]>);
	int _vfiprintf_r(struct _reent *<[reent]>, FILE *<[fp]>,
                        const char *<[fmt]>, va_list <[list]>);
	int _vsiprintf_r(struct _reent *<[reent]>, char *<[str]>,
                        const char *<[fmt]>, va_list <[list]>);
	int _vsniprintf_r(struct _reent *<[reent]>, char *<[str]>,
                          size_t <[size]>, const char *<[fmt]>,
                          va_list <[list]>);
	int _vasiprintf_r(struct _reent *<[reent]>, char **<[str]>,
                          const char *<[fmt]>, va_list <[list]>);
	char *_vasniprintf_r(struct _reent *<[reent]>, char *<[str]>,
                             size_t *<[size]>, const char *<[fmt]>,
                             va_list <[list]>);

DESCRIPTION
<<viprintf>>, <<vfiprintf>>, <<vasiprintf>>, <<vsiprintf>>,
<<vsniprintf>>, and <<vasniprintf>> are (respectively) variants of
<<iprintf>>, <<fiprintf>>, <<asiprintf>>, <<siprintf>>, <<sniprintf>>,
and <<asniprintf>>.  They differ only in allowing their caller to pass
the variable argument list as a <<va_list>> object (initialized by
<<va_start>>) rather than directly accepting a variable number of
arguments.  The caller is responsible for calling <<va_end>>.

<<_viprintf_r>>, <<_vfiprintf_r>>, <<_vasiprintf_r>>,
<<_vsiprintf_r>>, <<_vsniprintf_r>>, and <<_vasniprintf_r>> are
reentrant versions of the above.

RETURNS
The return values are consistent with the corresponding functions:

PORTABILITY
All of these functions are newlib extensions.

Supporting OS subroutines required: <<close>>, <<fstat>>, <<isatty>>,
<<lseek>>, <<read>>, <<sbrk>>, <<write>>.
*/

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#ifdef _HAVE_STDC
#include <stdarg.h>
#else
#include <varargs.h>
#endif
#include "local.h"

#ifndef _REENT_ONLY

int
_DEFUN(viprintf, (fmt, ap),
       _CONST char *fmt _AND
       va_list ap)
{
  _REENT_SMALL_CHECK_INIT (_REENT);
  return _vfiprintf_r (_REENT, _stdout_r (_REENT), fmt, ap);
}

#endif /* !_REENT_ONLY */

int
_DEFUN(_viprintf_r, (ptr, fmt, ap),
       struct _reent *ptr _AND
       _CONST char *fmt   _AND
       va_list ap)
{
  _REENT_SMALL_CHECK_INIT (ptr);
  return _vfiprintf_r (ptr, _stdout_r (ptr), fmt, ap);
}

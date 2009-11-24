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
<<fcloseall>>---close all files

INDEX
	fcloseall
INDEX
	_fcloseall_r

ANSI_SYNOPSIS
	#include <stdio.h>
	int fcloseall(void);
	int _fcloseall_r (struct _reent *<[ptr]>);

TRAD_SYNOPSIS
	#include <stdio.h>
	int fcloseall()

	int _fcloseall_r (<[ptr]>)
	struct _reent *<[ptr]>;

DESCRIPTION
<<fcloseall>> closes all files in the current reentrancy struct's domain.
The function <<_fcloseall_r>> is the same function, except the reentrancy
struct is passed in as the <[ptr]> argument.

This function is not recommended as it closes all streams, including
the std streams.

RETURNS
<<fclose>> returns <<0>> if all closes are successful.  Otherwise,
EOF is returned.

PORTABILITY
<<fcloseall>> is a glibc extension.

Required OS subroutines: <<close>>, <<fstat>>, <<isatty>>, <<lseek>>,
<<read>>, <<sbrk>>, <<write>>.
*/
/* This file based upon fwalk.c. */

#include <_ansi.h>
#include <reent.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include "local.h"

int
_DEFUN(_fcloseall_r, (ptr),
       struct _reent *ptr)
{
  return _fwalk_reent (ptr, _fclose_r);
}

#ifndef _REENT_ONLY

int
_DEFUN_VOID(fcloseall)
{
  return _fcloseall_r (_GLOBAL_REENT);
}

#endif

/*
 * ====================================================
 * Copyright (C) 1998, 2002 by Red Hat Inc. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice
 * is preserved.
 * ====================================================
 */

#if !defined(_SOFT_FLOAT)

/*
Fast version of atan2f using Intel float instructions.

   float _f_atan2f (float y, float x);

Function computes arctan ( y / x ).
There is no error checking or setting of errno.
*/

	#include "i386mach.h"

	.global SYM (_f_atan2f)
       SOTYPE_FUNCTION(_f_atan2f)

SYM (_f_atan2f):
	pushl ebp
	movl esp,ebp
	flds 8(ebp)
	flds 12(ebp)
	fpatan

	leave
	ret

#endif

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
Fast version of atan2 using Intel float instructions.

   double _f_atan2 (double y, double x);

Function computes arctan ( y / x ).
There is no error checking or setting of errno.
*/
	
	#include "i386mach.h"

	.global SYM (_f_atan2)
       SOTYPE_FUNCTION(_f_atan2)

SYM (_f_atan2):
	pushl ebp
	movl esp,ebp
	fldl 8(ebp)
	fldl 16(ebp)
	fpatan

	leave
	ret

#endif

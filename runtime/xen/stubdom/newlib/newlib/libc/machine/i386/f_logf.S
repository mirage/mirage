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
Fast version of logf using Intel float instructions.

   float _f_logf (float x);

Function calculates the log base e of x.
There is no error checking or setting of errno. 
*/

	#include "i386mach.h"

	.global SYM (_f_logf)
       SOTYPE_FUNCTION(_f_logf)

SYM (_f_logf):
	pushl ebp
	movl esp,ebp

	fld1
	fldl2e
	fdivrp
	flds 8(ebp)
	fyl2x

	leave
	ret

#endif

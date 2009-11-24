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
Fast version of tan using Intel float instructions.

   double _f_tan (double x);

Function calculates the tangent of x.
There is no error checking or setting of errno. 
*/

	#include "i386mach.h"

	.global SYM (_f_tan)
       SOTYPE_FUNCTION(_f_tan)

SYM (_f_tan):
	pushl ebp
	movl esp,ebp
	fldl 8(ebp)
	fptan
	fincstp

	leave
	ret

#endif

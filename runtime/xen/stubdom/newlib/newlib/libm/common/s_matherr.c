
/* @(#)s_matherr.c 5.1 93/09/24 */
/*
 * ====================================================
 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 *
 * Developed at SunPro, a Sun Microsystems, Inc. business.
 * Permission to use, copy, modify, and distribute this
 * software is freely granted, provided that this notice 
 * is preserved.
 * ====================================================
 */

/*

FUNCTION
	<<matherr>>---modifiable math error handler

INDEX 
	matherr

ANSI_SYNOPSIS
	#include <math.h>
	int matherr(struct exception *<[e]>);

TRAD_SYNOPSIS
	#include <math.h>
	int matherr(*<[e]>)
	struct exception *<[e]>;

DESCRIPTION
<<matherr>> is called whenever a math library function generates an error.
You can replace <<matherr>> by your own subroutine to customize
error treatment.  The customized <<matherr>> must return 0 if
it fails to resolve the error, and non-zero if the error is resolved.

When <<matherr>> returns a nonzero value, no error message is printed
and the value of <<errno>> is not modified.  You can accomplish either
or both of these things in your own <<matherr>> using the information
passed in the structure <<*<[e]>>>.

This is the <<exception>> structure (defined in `<<math.h>>'):
.	struct exception {
.	        int type;
.	        char *name;
.	        double arg1, arg2, retval;
.		int err;
.	};

The members of the exception structure have the following meanings:
o+
o type
The type of mathematical error that occured; macros encoding error
types are also defined in `<<math.h>>'.

o name
a pointer to a null-terminated string holding the
name of the math library function where the error occurred.

o arg1, arg2
The arguments which caused the error.

o retval
The error return value (what the calling function will return).

o err
If set to be non-zero, this is the new value assigned to <<errno>>.
o-

The error types defined in `<<math.h>>' represent possible mathematical
errors as follows:

o+
o DOMAIN
An argument was not in the domain of the function; e.g. <<log(-1.0)>>.

o SING
The requested calculation would result in a singularity; e.g. <<pow(0.0,-2.0)>>

o OVERFLOW
A calculation would produce a result too large to represent; e.g.
<<exp(1000.0)>>. 

o UNDERFLOW
A calculation would produce a result too small to represent; e.g.
<<exp(-1000.0)>>. 

o TLOSS
Total loss of precision.  The result would have no significant digits;
e.g. <<sin(10e70)>>. 

o PLOSS
Partial loss of precision.
o-


RETURNS
The library definition for <<matherr>> returns <<0>> in all cases.

You can change the calling function's result from a customized <<matherr>>
by modifying <<e->retval>>, which propagates backs to the caller.

If <<matherr>> returns <<0>> (indicating that it was not able to resolve
the error) the caller sets <<errno>> to an appropriate value, and prints
an error message.

PORTABILITY
<<matherr>> is not ANSI C.  
*/

#include "fdlibm.h"

#ifdef __STDC__
	int matherr(struct exception *x)
#else
	int matherr(x)
	struct exception *x;
#endif
{
	int n=0;
	if(x->arg1!=x->arg1) return 0;
	return n;
}

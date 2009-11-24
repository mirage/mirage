
/* @(#)w_jn.c 5.1 93/09/24 */
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
<<jN>>, <<jNf>>, <<yN>>, <<yNf>>---Bessel functions

INDEX
j0
INDEX
j0f
INDEX
j1
INDEX
j1f
INDEX
jn
INDEX
jnf
INDEX
y0
INDEX
y0f
INDEX
y1
INDEX
y1f
INDEX
yn
INDEX
ynf

ANSI_SYNOPSIS
#include <math.h>
double j0(double <[x]>);
float j0f(float <[x]>);
double j1(double <[x]>);
float j1f(float <[x]>);
double jn(int <[n]>, double <[x]>);
float jnf(int <[n]>, float <[x]>);
double y0(double <[x]>);
float y0f(float <[x]>);
double y1(double <[x]>);
float y1f(float <[x]>);
double yn(int <[n]>, double <[x]>);
float ynf(int <[n]>, float <[x]>);

TRAD_SYNOPSIS
#include <math.h>

double j0(<[x]>)
double <[x]>;
float j0f(<[x]>)
float <[x]>;
double j1(<[x]>)
double <[x]>;
float j1f(<[x]>)
float <[x]>;
double jn(<[n]>, <[x]>)
int <[n]>;
double <[x]>;
float jnf(<[n]>, <[x]>)
int <[n]>;
float <[x]>;

double y0(<[x]>)
double <[x]>;
float y0f(<[x]>)
float <[x]>;
double y1(<[x]>)
double <[x]>;
float y1f(<[x]>)
float <[x]>;
double yn(<[n]>, <[x]>)
int <[n]>;
double <[x]>;
float ynf(<[n]>, <[x]>)
int <[n]>;
float <[x]>;

DESCRIPTION
The Bessel functions are a family of functions that solve the
differential equation
@ifnottex
.  2               2    2
. x  y'' + xy' + (x  - p )y  = 0
@end ifnottex
@tex
$$x^2{d^2y\over dx^2} + x{dy\over dx} + (x^2-p^2)y = 0$$
@end tex
These functions have many applications in engineering and physics.

<<jn>> calculates the Bessel function of the first kind of order
<[n]>.  <<j0>> and <<j1>> are special cases for order 0 and order
1 respectively.

Similarly, <<yn>> calculates the Bessel function of the second kind of
order <[n]>, and <<y0>> and <<y1>> are special cases for order 0 and
1.

<<jnf>>, <<j0f>>, <<j1f>>, <<ynf>>, <<y0f>>, and <<y1f>> perform the
same calculations, but on <<float>> rather than <<double>> values.

RETURNS
The value of each Bessel function at <[x]> is returned.

PORTABILITY
None of the Bessel functions are in ANSI C.
*/

/*
 * wrapper jn(int n, double x), yn(int n, double x)
 * floating point Bessel's function of the 1st and 2nd kind
 * of order n
 *          
 * Special cases:
 *	y0(0)=y1(0)=yn(n,0) = -inf with division by zero signal;
 *	y0(-ve)=y1(-ve)=yn(n,-ve) are NaN with invalid signal.
 * Note 2. About jn(n,x), yn(n,x)
 *	For n=0, j0(x) is called,
 *	for n=1, j1(x) is called,
 *	for n<x, forward recursion us used starting
 *	from values of j0(x) and j1(x).
 *	for n>x, a continued fraction approximation to
 *	j(n,x)/j(n-1,x) is evaluated and then backward
 *	recursion is used starting from a supposed value
 *	for j(n,x). The resulting value of j(0,x) is
 *	compared with the actual value to correct the
 *	supposed value of j(n,x).
 *
 *	yn(n,x) is similar in all respects, except
 *	that forward recursion is used for all
 *	values of n>1.
 *	
 */

#include "fdlibm.h"
#include <errno.h>

#ifndef _DOUBLE_IS_32BITS

#ifdef __STDC__
	double jn(int n, double x)	/* wrapper jn */
#else
	double jn(n,x)			/* wrapper jn */
	double x; int n;
#endif
{
#ifdef _IEEE_LIBM
	return jn(n,x);
#else
	double z;
	struct exception exc;
	z = jn(n,x);
	if(_LIB_VERSION == _IEEE_ || isnan(x) ) return z;
	if(fabs(x)>X_TLOSS) {
	    /* jn(|x|>X_TLOSS) */
            exc.type = TLOSS;
            exc.name = "jn";
	    exc.err = 0;
	    exc.arg1 = n;
	    exc.arg2 = x;
            exc.retval = 0.0;
            if (_LIB_VERSION == _POSIX_)
                errno = ERANGE;
            else if (!matherr(&exc)) {
               errno = ERANGE;
            }        
	    if (exc.err != 0)
	       errno = exc.err;
            return exc.retval; 
	} else
	    return z;
#endif
}

#ifdef __STDC__
	double yn(int n, double x)	/* wrapper yn */
#else
	double yn(n,x)			/* wrapper yn */
	double x; int n;
#endif
{
#ifdef _IEEE_LIBM
	return yn(n,x);
#else
	double z;
	struct exception exc;
	z = yn(n,x);
	if(_LIB_VERSION == _IEEE_ || isnan(x) ) return z;
        if(x <= 0.0){
	    /* yn(n,0) = -inf or yn(x<0) = NaN */
#ifndef HUGE_VAL 
#define HUGE_VAL inf
	    double inf = 0.0;

	    SET_HIGH_WORD(inf,0x7ff00000);	/* set inf to infinite */
#endif
	    exc.type = DOMAIN;	/* should be SING for IEEE */
	    exc.name = "yn";
	    exc.err = 0;
	    exc.arg1 = n;
	    exc.arg2 = x;
	    if (_LIB_VERSION == _SVID_)
	        exc.retval = -HUGE;
	    else
	        exc.retval = -HUGE_VAL;
	    if (_LIB_VERSION == _POSIX_)
	        errno = EDOM;
	    else if (!matherr(&exc)) {
	        errno = EDOM;
	    }
	    if (exc.err != 0)
	       errno = exc.err;
            return exc.retval; 
        }
	if(x>X_TLOSS) {
	    /* yn(x>X_TLOSS) */
            exc.type = TLOSS;
            exc.name = "yn";
	    exc.err = 0;
	    exc.arg1 = n;
	    exc.arg2 = x;
            exc.retval = 0.0;
            if (_LIB_VERSION == _POSIX_)
                errno = ERANGE;
            else if (!matherr(&exc)) {
                errno = ERANGE;
            }        
	    if (exc.err != 0)
	       errno = exc.err;
            return exc.retval; 
	} else
	    return z;
#endif
}

#endif /* defined(_DOUBLE_IS_32BITS) */

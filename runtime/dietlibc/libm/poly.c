/*--------------------------------------------------------------------------*

Name		__poly - generates a polynomial from arguments

Usage		double  __poly ( double x, int n, const double* c );

Prototype in	math.h

Description	__poly generates a polynomial in x, of degree n, with
		coefficients c[0], c[1], ..., c[n]. For example, if n=4,
		the generated polynomial is

			c[4]*x^4 + c[3]*x^3 + c[2]*x^2 + c[1]*x + c[0]

		The polynomial is calculated using Horner's method:

			polynom = (..((x*c[n] + c[n-1])*x + c[n-2])..)*x + c[0]

Return value	__poly returns the value of the polynomial as evaluated for
		the given x.
		A range error occurs if the result exceeds double range.

*---------------------------------------------------------------------------*/

#include <stdio.h>
#include "dietlibm.h"

double  __poly ( double x, size_t n, const double* c) 
{
    long double ret;
    size_t      i;
    
    i   = n;
    c  += n;
    ret = 0;
    do
        ret = ret * x + *c--;
    while ( i-- );
    
    return ret;
}

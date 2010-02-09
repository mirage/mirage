#include "dietlibm.h"

/*--------------------------------------------------------------------------*

Name            gamma, lgamma - gamma function

Usage           double gamma (double x);
                double lgamma(double x);
                extern int signgam;

Prototype in    math.h

Description     gamma returns the logarithm of the absolute value of the
                gamma function. So it is possible â(x) for very large x.
                The sign is stored in signgam, a extern variable
                overwritten during every call to gamma(). lgamma() is
                a synonym for gamma().
                You can calculate â(x) by the following sequence:

                double gammafunction(double x)
                  { double y=exp(gamma(x));

                    return signgam ? -y : +y;
                  }

Return value    gamma returns a value in range (-0.1208, +oo). For a input
                value of zero, it returns +oo and errno is set to:

                        ERANGE  Result out of range

*---------------------------------------------------------------------------*/

#include <stdlib.h>
#include <math.h>

#define B0      +            1.0l/   6/ 1/ 2
#define B1      -            1.0l/  30/ 3/ 4
#define B2      +            1.0l/  42/ 5/ 6
#define B3      -            1.0l/  30/ 7/ 8
#define B4      +            5.0l/  66/ 9/10
#define B5      -          691.0l/2730/11/12
#define B6      +            7.0l/   6/13/14
#define B7      -         3617.0l/ 510/15/16
#define B8      +        43867.0l/ 798/17/18
#define B9      -       174611.0l/ 330/19/20
#define B10     +       854513.0l/ 138/21/22
#define B11     -    236364091.0l/2730/23/24
#define B12     +      8553103.0l/   6/25/26

static const double  coeff[] = { B0, B1, B2, B3, B4, B5, B6, B7, B8, B9, B10 };
int                  signgam;

#define EXPL(x) (((short *)(void *)&x)[4] & 0x7FFF)

static double  logfact ( long double x )
{
    long double   z = 2. * M_PI * x;
    register int  e = EXPL (x);
   
    static unsigned char list [] = { 6, 4, 3, 3, 2, 2 };

    return (log(x) - 1) * x + 0.5*log(z) + __poly (1./(x*x), e<0x4003 ? 10 : (e>0x4008 ? 1 : list [e-0x4003] ), coeff) / x;
}


double  lgamma ( double x )
{
    register int  k = floor (x);
    long double   w;
    long double   y;
    long double   z;
   
    signgam = 0;

    if ( k >= 7 )
        return logfact (x-1);
       
    if ( k == x )
        switch (k) {
        case 1 :
        case 2 : return 0.000000000000000000000000000l;
        case 3 : return 0.693147180559945309432805516l;
        case 4 : return 1.791759469228055000858148560l;
        case 5 : return 3.178053830347945619723759592l;
        case 6 : return 4.787491742782045994244981560l;
        default: return 1./0.; /* ignore the gcc warning, this is intentional */
        }
       
    z = logfact (y = x - k + 7.0 - 1);
    w = 1;
    for ( k = 7 - k; k--; )
        w *= y, y -= 1.;
       
    signgam = k >= 0  ?  0  :  k & 1;
    return z - log (w);
}

double gamma ( double val )  __attribute__ ((weak,alias("lgamma")));

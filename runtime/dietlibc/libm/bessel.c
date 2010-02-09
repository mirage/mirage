/*--------------------------------------------------------------------------*

Name            j0, j1, jn - Bessel functions
                y0, y1, yn - Weber functions

Usage           double j0 (double x);
                double j1 (double x);
                double jn (int n, double x);
                double y0 (double x);
                double y1 (double x);
                double yn (int n, double x);

Prototype in    math.h

Description     j0, j1 and jn calculate the Bessel function.
                y0, y1 and yn calcualte the Weber function.

Return value    return their return values as doubles.

*---------------------------------------------------------------------------*/

#include <math.h>

#define M_C             0.5772156649015328
#if 0
#define M_1_PI          0.318309886183790671538
#define M_2_PI          0.636619772367581343076
#define M_PI            3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148
#endif


#define EXPL(x)   ((((short *)(void *)&x)[4] & 0x7FFF) >> 0)
#define EXPD(x)   ((((short *)(void *)&x)[3] & 0x7FF0) >> 4)
#define EXPF(x)   ((((short *)(void *)&x)[1] & 0x7F80) >> 7)

#define SQUARE(x) (long) (My - (x) * (x) )


static long double  P ( int My, double* x )
{
    long double   Sum  = 0.;
    long double   Fact = 1.;
    long double   z182 = -0.015625 / (x[0] * x[0]);
    register int  i;

    for ( i = 1; ; i += 2 ) {
        Fact *= SQUARE(i+i-1) * SQUARE(i+i+1) * z182 / (i*(i+1));
        if ( EXPL (Fact) < 0x3FFF-53 )
            break;
        Sum  += Fact;
    }
    return 1. + Sum;
}

static long double  Q ( int My, double* x )
{
    long double   Fact = (My-1) / x[0] * 0.125;
    long double   Sum  = Fact;
    long double   z182 = -0.015625 / (x[0]*x[0]);
    register int  i;

    for ( i = 2; ; i += 2 ) {
        Fact *= SQUARE(i+i-1) * SQUARE(i+i+1) * z182 / (i*(i+1));
        if ( EXPL (Fact) < 0x3FFF-53 )
            break;
        Sum  += Fact;
    }
    return Sum;
}


static long double  ___jn ( int n, double* x )
{
    long double   Sum;
    long double   Fact;
    long double   y;
    register int  i;
    double        xx;
    long double   Xi;
    int           My;

    if ( n < 0 )
        return n & 1 ? ___jn (-n, x) : -___jn (-n, x);

    if ((x[0] >= 17.7+0.0144*(n*n))) {
        Xi = x[0] - M_PI * (n*0.5 + 0.25);
        My = n*n << 2;

        return sqrt ( M_2_PI/x[0] ) * ( P(My,x) * cos(Xi) - Q(My,x) * sin(Xi) );
    }
    xx   = x[0] * 0.5;
    Sum  = 0.;
    Fact = 1.;
    y    = -xx * xx;

    for ( i = 1; i <= n; i++ )
        Fact *= xx/i;
    for ( i = 1; ; i++ ) {
        Sum  += Fact;
        Fact *= y / (i*(n+i));
        if ( EXPL (Sum) - EXPL(Fact) > 53 || !EXPL(Fact) )
            break;
    }
    return Sum;
}


static long double  ___yn ( int n, double* x )
{
    long double   Sum1;
    long double   Sum2;
    long double   Fact1;
    long double   Fact2;
    long double   F1;
    long double   F2;
    long double   y;
    register int  i;
    double        xx;
    long double   Xi;
    unsigned int  My;

    if ( EXPD (x[0]) == 0 )
        return -1./0.;	/* ignore the gcc warning, this is intentional */

    if ( (x[0] >= (n>=32 ? 25.8 : (n<8 ? 17.4+0.1*n : 16.2+0.3*n))) ) {
        Xi = x[0] - M_PI * (n*0.5+0.25);
        My = n*n << 2;

        return sqrt ( M_2_PI / x[0] ) * ( P(My,x) * sin(Xi) + Q(My,x) * cos(Xi) );
    }

    Sum1  = Sum2 = F1 = F2 = 0;
    Fact1 = 1. / (xx = x[0] * 0.5 );
    Fact2 = 1.;
    y     = xx*xx;

    for ( i = 1; i < n; i++ )
        Fact1 *= (n-i) / xx;

    for ( i = 1; i <= n; i++ ) {
        Sum1  += Fact1;
        if ( i == n )
            break;
        Fact1 *= y/(i*(n-i));
    }

    for (i=1; i<=n; i++) {
        Fact2 *= xx / i;
        F1    += 1. / i;
    }

    for ( i = 1; ; i++ ) {
        Sum2  += Fact2 * (F1+F2);
        Fact2 *= -y / (i*(n+i));
        if ( EXPL (Sum2) - EXPL (Fact2) > 53 || !EXPL (Fact2) )
            break;
        F1 += 1. / (n+i);
        F2 += 1. / i;
    }

    return M_1_PI * (2. * (M_C + log(xx)) * ___jn (n, x) - Sum1 - Sum2);
}


double  j0 ( double x )         { return ___jn ( 0,&x ); }
double  j1 ( double x )         { return ___jn ( 1,&x ); }
double  jn ( int n, double x )  { return ___jn ( n,&x ); }
double  y0 ( double x )         { return ___yn ( 0,&x ); }
double  y1 ( double x )         { return ___yn ( 1,&x ); }
double  yn ( int n, double x )  { return ___yn ( n,&x ); }


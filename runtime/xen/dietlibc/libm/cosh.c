#include <math.h>

extern const float  __half;

double  cosh ( double x )
{
    long double  y = exp (x);
    return (y + 1./y) * __half;
}

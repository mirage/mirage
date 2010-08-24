#include <math.h>

double  tanh ( double x )
{
    long double  y = exp (x + x);
    return (y - 1.) / (y + 1.);
}

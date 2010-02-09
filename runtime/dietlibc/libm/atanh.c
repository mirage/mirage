#include <math.h>

extern const float  __half;

double  atanh ( double x )
{
    return __half * log ( (1.+x) / (1.-x) );
}

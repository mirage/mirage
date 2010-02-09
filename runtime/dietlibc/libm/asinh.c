#include <math.h>

double  asinh ( double x )
{
    return log ( x + sqrt (x*x + 1.) );
}

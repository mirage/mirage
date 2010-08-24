#include <math.h>

double  acosh ( double x )
{
    return log ( x + sqrt (x*x - 1.) );
}

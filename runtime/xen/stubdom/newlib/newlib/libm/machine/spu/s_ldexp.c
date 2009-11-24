#include <math.h>
#include "headers/ldexp.h"

double ldexp(double x, int exp)
{
    return _ldexp(x, exp);
}

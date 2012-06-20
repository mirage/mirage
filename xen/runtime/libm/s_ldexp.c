#include <sys/cdefs.h>
#include <float.h>
#include <math.h>

#include "math_private.h"

double
ldexp (double x, int n)
{
    return scalbn(x, n);
}

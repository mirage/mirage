#include <math.h>
#include "headers/frexpf.h"

float frexpf(float x, int *pexp)
{
    return _frexpf(x, pexp);
}

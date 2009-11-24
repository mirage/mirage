#include <math.h>
#include "headers/erf.h"

double erf(double x)
{
  return _erf(x);
}

/*
 * The default s_erf.c contains both erf and erfc, erfc was manually added
 * here, it could be moved to a separate file (similar for sf_erf.c).
 */
#include "headers/erfc.h"

double erfc(double x)
{
  return _erfc(x);
}

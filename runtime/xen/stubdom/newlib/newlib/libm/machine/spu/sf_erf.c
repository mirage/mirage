#include <math.h>
#include "headers/erff.h"

float erff(float x)
{
  return _erff(x);
}

/*
 * The default sf_erf.c contains both erff and erfcf, erfcf was manually added
 * here, it could be moved to a separate file (similar to s_erf.c).
 */
#include "headers/erfcf.h"

float erfcf(float x)
{
  return _erfcf(x);
}

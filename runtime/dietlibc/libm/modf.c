#include <math.h>

double modf(double x, double *iptr) {
  double fmod_result = fmod(x,1.0);
  *iptr = x - fmod_result;
  return fmod_result;
}

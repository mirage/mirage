#include <stdlib.h>

double atof(const char *nptr) {
#if 0
  return strtod(nptr,0);
#else
  double tmp=strtod(nptr,0);
  return tmp;
#endif
}

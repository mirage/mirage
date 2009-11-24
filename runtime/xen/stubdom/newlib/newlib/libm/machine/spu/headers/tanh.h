#include "headers/tanhd2.h"

static __inline double _tanh(double x)
{
  return spu_extract(_tanhd2(spu_promote(x, 0)), 0);
}

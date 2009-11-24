#include <stdlib.h>

int 
_mallopt_r (struct _reent *ptr, int param_number, int value)
{
  return mallopt (param_number, value);
}

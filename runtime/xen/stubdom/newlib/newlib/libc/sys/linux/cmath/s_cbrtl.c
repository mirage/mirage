#include <math.h>
#include <stdio.h>
#include <errno.h>

long double
__cbrtl(long double x)
{
  fputs ("__cbrtl not implemented\n", stderr);
  __set_errno (ENOSYS);
  return 0.0;
}

weak_alias (__cbrtl, cbrtl)
stub_warning (cbrtl)
#include <stub-tag.h>

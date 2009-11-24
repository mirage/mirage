#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <sys/time.h>
#include <sys/times.h>
#include <errno.h>

struct timeval;
struct timezone;

int gettimeofday(struct timeval *ptimeval, void *ptimezone)
{
  errno = ENOSYS;
  return -1;
}

#include "config.h"
#include <_ansi.h>
#include <_syslist.h>
#include <sys/times.h>
#include <errno.h>

clock_t times(struct tms *buf)
{
  errno = ENOSYS;
  return -1;
}

#include <errno.h>
#include <sys/time.h>
#include <time.h>
#include <syscalls.h>

#ifndef __NR_stime
int stime(time_t *when)
{
  struct timeval tv;
  tv.tv_sec = *when;
  tv.tv_usec = 0;
  return settimeofday(&tv, (struct timezone *)0);
}
#endif

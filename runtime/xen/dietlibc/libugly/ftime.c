#include <sys/time.h>
#include <sys/timeb.h>
#include <unistd.h>

int ftime(struct timeb *tp) {
  struct timeval tv;
  struct timezone tz;
  int ret=gettimeofday(&tv,&tz);
  tp->time	= tv.tv_sec;
  tp->millitm	= tv.tv_usec/1000;
  tp->timezone	= tz.tz_minuteswest;
  tp->dstflag	= tz.tz_dsttime;
  return ret;
}


#define _GNU_SOURCE
#include <sys/cdefs.h>
#undef __attribute_dontuse__
#define __attribute_dontuse__
#include <time.h>
#include "dietfeatures.h"

#ifdef WANT_TZFILE_PARSER
extern void __maplocaltime(void);
extern time_t __tzfile_map(time_t t, int *isdst, int forward);
#else
extern long int timezone;
extern int daylight;
#endif

time_t mktime(register struct tm* const t) {
  time_t x=timegm(t);
#ifdef WANT_TZFILE_PARSER
  int isdst;
  time_t y;
  __maplocaltime();
  x=__tzfile_map(x,&isdst,0);
#else
  struct timezone tz;
  gettimeofday(0, &tz);
  timezone=tz.tz_minuteswest*60L;
  x+=timezone;
#endif
  return x;
}

time_t timelocal(struct tm* const t) __attribute__((alias("mktime")));


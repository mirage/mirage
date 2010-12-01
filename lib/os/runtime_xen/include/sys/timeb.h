#ifndef __SYS_TIMEB_H
#define __SYS_TIMEB_H 1

#include <sys/cdefs.h>

__BEGIN_DECLS

struct timeb {
  time_t   time;
  unsigned short millitm;
  short    timezone;
  short    dstflag;
};

int ftime(struct timeb *tp);

__END_DECLS

#endif

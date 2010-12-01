#ifndef _SYS_TIMERFD_H
#define _SYS_TIMERFD_H

#include <time.h>

enum { TFD_TIMER_ABSTIME = 1 };

__BEGIN_DECLS

int timerfd_create (clockid_t clock_id, int flags) __THROW;
int timerfd_settime (int ufd, int flags, const struct itimerspec *utmr, struct itimerspec *otmr) __THROW;
int timerfd_gettime (int ufd, struct itimerspec *otmr) __THROW;

__END_DECLS

#endif

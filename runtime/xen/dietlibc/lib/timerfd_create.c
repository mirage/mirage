#include <sys/timerfd.h>

extern int __timerfd(int ufd, int clockid, int flags, const struct itimerspec *utmr);

int timerfd_create (clockid_t __clock_id, int __flags) {
  return __timerfd(-1,__clock_id,__flags,0);
}

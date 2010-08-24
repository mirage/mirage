#include <signal.h>

int __rt_sigtimedwait(const sigset_t *set, siginfo_t *info, const struct timespec *ts, long nr);

int sigtimedwait(const sigset_t *set, siginfo_t *info, const struct timespec *ts) {
  return __rt_sigtimedwait(set,info,ts,_NSIG/8);
}

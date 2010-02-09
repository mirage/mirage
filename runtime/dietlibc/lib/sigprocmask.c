#include <signal.h>

int __rt_sigprocmask(int how, const sigset_t *set, sigset_t *oldsetm, long nr);

int sigprocmask(int how, const sigset_t *set, sigset_t *oldset) {
  return __rt_sigprocmask(how, set, oldset, _NSIG/8);
}

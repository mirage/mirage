#include <signal.h>

int __rt_sigpending(sigset_t *set, long nr);

int sigpending(sigset_t *set) {
  return __rt_sigpending(set, _NSIG/8);
}

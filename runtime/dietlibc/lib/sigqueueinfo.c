#include <signal.h>

int __rt_sigqueueinfo(pid_t pid, int sig, siginfo_t *info);

int sigqueueinfo(pid_t pid, int sig, siginfo_t *info) {
  return __rt_sigqueueinfo(pid, sig, info);
}

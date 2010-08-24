#include <signal.h>

int siginterrupt(int sig, int flag) {
  int ret;
  struct sigaction act;

  sigaction(sig, 0, &act);

  if (flag)
    act.sa_flags &= ~SA_RESTART;
  else
    act.sa_flags |= SA_RESTART;

  ret = sigaction(sig, &act, 0);

  return ret;
}

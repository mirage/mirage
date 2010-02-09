#include <signal.h>

sighandler_t signal(int signum, sighandler_t action) {
  struct sigaction sa,oa;
  sa.sa_handler=action;
  sigemptyset(&sa.sa_mask);
  if (sigaddset(&sa.sa_mask,signum) != 0)
    return SIG_ERR;
  sa.sa_flags = SA_NODEFER; /* FIXME ??? */
  if (sigaction(signum,&sa,&oa) != 0)
    return SIG_ERR;
  return oa.sa_handler;
}

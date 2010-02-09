#include <unistd.h>

#include <pthread.h>
#include "thread_internal.h"

int sigaction(int signum,const struct sigaction*act,struct sigaction*old) {
  if ((signum==PTHREAD_SIG_RESTART)||(signum==PTHREAD_SIG_CANCEL)) {
    _errno_=EINVAL;
    return -1;
  }
  return __libc_sigaction(signum,act,old);
}


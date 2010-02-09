#include <signal.h>

#include <pthread.h>
#include "thread_internal.h"

static int _pthread_kill(pthread_t th,int sig) {
  int ret=ESRCH;
  _pthread_descr td;
  if (th==getpid()) {
    ret=(kill(th,sig)==-1)?_errno_:0;
  }
  else {
    _pthread_descr this=__thread_self();
    __NO_ASYNC_CANCEL_BEGIN_(this);
    if ((td=__thread_find(th))) {
      UNLOCK(td);
      ret=(kill(th,sig)==-1)?_errno_:0;
    }
    __NO_ASYNC_CANCEL_END_(this);
  }
  return ret;
}
int pthread_kill(pthread_t th,int sig) __attribute__((alias("_pthread_kill")));

int pthread_cancel(pthread_t th) {
  return _pthread_kill(th,PTHREAD_SIG_CANCEL);
}

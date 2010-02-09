#include <unistd.h>
#include <errno.h>
#include <string.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_cond_destroy(pthread_cond_t*cond) {
  _pthread_descr this=__thread_self();
  int ret=0;

  __NO_ASYNC_CANCEL_BEGIN_(this);
  LOCK(cond);

  if (cond->wait_chain) {
    UNLOCK(cond);
    ret=EBUSY;
  }
  else {
    memset(cond,0,sizeof(pthread_cond_t));
    cond->lock.__spinlock=PTHREAD_SPIN_UNLOCKED;
  }
  __NO_ASYNC_CANCEL_END_(this);
  return ret;
}


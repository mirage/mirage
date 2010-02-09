#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_cond_signal(pthread_cond_t*cond) {
  _pthread_descr this=__thread_self();
  __NO_ASYNC_CANCEL_BEGIN_(this);
  LOCK(cond);

  if (cond->wait_chain) __thread_restart(cond->wait_chain);

  UNLOCK(cond);
  __NO_ASYNC_CANCEL_END_(this);
  return 0;
}


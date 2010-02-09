#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_cond_broadcast(pthread_cond_t*cond) {
  _pthread_descr this=__thread_self();
  _pthread_descr tmp,next;

  __NO_ASYNC_CANCEL_BEGIN_(this);
  LOCK(cond);

  for (tmp=cond->wait_chain;tmp;tmp=next) {
    next=tmp->waitnext;
    __thread_restart(tmp);
    tmp->waitnext=0;
    tmp->waitprev=&(tmp->waitnext);
  }
  cond->wait_chain=0;

  UNLOCK(cond);
  __NO_ASYNC_CANCEL_END_(this);

  return 0;
}


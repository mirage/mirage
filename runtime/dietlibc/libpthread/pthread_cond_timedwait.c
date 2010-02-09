#include <unistd.h>
#include <errno.h>

#include <pthread.h>
#include "thread_internal.h"

int pthread_cond_timedwait(pthread_cond_t*cond,pthread_mutex_t*mutex,
		      const struct timespec*abstime) {
  _pthread_descr this=__thread_self();
  _pthread_descr*tmp;
  int retval;

  if (mutex->owner!=this) return EINVAL;

  __NO_ASYNC_CANCEL_BEGIN_(this);

  /* put in wait-chain */
  LOCK(cond);
  tmp=&(cond->wait_chain);
  this->waitnext=0;
  while (*tmp) tmp=&((*tmp)->waitnext);
  this->waitprev=tmp;
  *tmp=this;
  UNLOCK(cond);

  /* Aeh yeah / wait till condition-signal or timout (or cancel) */
  pthread_mutex_unlock(mutex);

  retval = __thread_suspend_till(this,1,abstime);

  pthread_mutex_lock(mutex);

  /* remove from wait-chain (if not signaled) */
  LOCK(cond);
  if (this->waitnext) {
    this->waitnext->waitprev=this->waitprev;
    *(this->waitprev)=this->waitnext;
  }
  else *(this->waitprev)=0;
  UNLOCK(cond);

  __NO_ASYNC_CANCEL_END_(this);

  return retval;
}


